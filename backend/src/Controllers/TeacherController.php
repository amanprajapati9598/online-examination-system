<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../Models/Exam.php';
require_once __DIR__ . '/../Models/Question.php';
require_once __DIR__ . '/../Models/StudentExam.php';
require_once __DIR__ . '/../Middleware/AuthMiddleware.php';

class TeacherController {
    private $db;
    private $examModel;
    private $questionModel;
    private $studentExamModel;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->examModel = new Exam($this->db);
        $this->questionModel = new Question($this->db);
        $this->studentExamModel = new StudentExam($this->db);
    }

    public function getExams() {
        $decoded = AuthMiddleware::authenticate(['teacher', 'admin']);
        // Admins can see all if they supply a teacher_id, otherwise show teacher's own
        $teacherId = ($decoded['role'] === 'admin' && isset($_GET['teacher_id'])) 
            ? intval($_GET['teacher_id']) 
            : $decoded['id'];

        $exams = $this->examModel->getByTeacher($teacherId);
        $this->respond(true, "Exams retrieved successfully", 200, ["exams" => $exams]);
    }

    public function getExamDetails() {
        AuthMiddleware::authenticate(['teacher', 'admin']);
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if (!$id) {
            $this->respond(false, "Exam ID required", 400);
        }

        $exam = $this->examModel->findById($id);
        if (!$exam) {
            $this->respond(false, "Exam not found", 404);
        }

        $this->respond(true, "Exam details retrieved", 200, ["exam" => $exam]);
    }

    public function createExam() {
        $decoded = AuthMiddleware::authenticate(['teacher']);
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['title']) || empty($data['subject_id']) || empty($data['duration_minutes']) || empty($data['start_time']) || empty($data['end_time']) || !isset($data['total_marks']) || !isset($data['passing_marks'])) {
            $this->respond(false, "Missing required exam fields", 400);
        }

        $examId = $this->examModel->create(
            $data['title'],
            $data['description'] ?? '',
            intval($data['subject_id']),
            $decoded['id'],
            intval($data['duration_minutes']),
            $data['start_time'],
            $data['end_time'],
            floatval($data['total_marks']),
            floatval($data['passing_marks']),
            floatval($data['negative_marking_factor'] ?? 0.00),
            intval($data['randomize_questions'] ?? 0),
            intval($data['randomize_options'] ?? 0),
            intval($data['anti_cheating_enabled'] ?? 1),
            intval($data['is_published'] ?? 0)
        );

        if ($examId) {
            $this->respond(true, "Exam created successfully", 201, ["exam_id" => $examId]);
        } else {
            $this->respond(false, "Failed to create exam", 500);
        }
    }

    public function updateExam() {
        AuthMiddleware::authenticate(['teacher']);
        $data = json_decode(file_get_contents("php://input"), true);
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if (!$id) {
            $this->respond(false, "Exam ID required", 400);
        }

        if (empty($data['title']) || empty($data['subject_id']) || empty($data['duration_minutes']) || empty($data['start_time']) || empty($data['end_time']) || !isset($data['total_marks']) || !isset($data['passing_marks'])) {
            $this->respond(false, "Missing required exam fields", 400);
        }

        $success = $this->examModel->update(
            $id,
            $data['title'],
            $data['description'] ?? '',
            intval($data['subject_id']),
            intval($data['duration_minutes']),
            $data['start_time'],
            $data['end_time'],
            floatval($data['total_marks']),
            floatval($data['passing_marks']),
            floatval($data['negative_marking_factor'] ?? 0.00),
            intval($data['randomize_questions'] ?? 0),
            intval($data['randomize_options'] ?? 0),
            intval($data['anti_cheating_enabled'] ?? 1),
            intval($data['is_published'] ?? 0)
        );

        if ($success) {
            $this->respond(true, "Exam updated successfully", 200);
        } else {
            $this->respond(false, "Failed to update exam", 500);
        }
    }

    public function deleteExam() {
        AuthMiddleware::authenticate(['teacher']);
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if (!$id) {
            $this->respond(false, "Exam ID required", 400);
        }

        if ($this->examModel->delete($id)) {
            $this->respond(true, "Exam deleted successfully", 200);
        } else {
            $this->respond(false, "Failed to delete exam", 500);
        }
    }

    public function getQuestions() {
        AuthMiddleware::authenticate(['teacher', 'admin']);
        $exam_id = isset($_GET['exam_id']) ? intval($_GET['exam_id']) : null;

        if (!$exam_id) {
            $this->respond(false, "Exam ID required", 400);
        }

        // Return exact questions without randomizing for editor
        $questions = $this->questionModel->getByExam($exam_id, false, false);
        $this->respond(true, "Questions retrieved successfully", 200, ["questions" => $questions]);
    }

    public function addQuestion() {
        AuthMiddleware::authenticate(['teacher']);
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['exam_id']) || empty($data['question_text']) || empty($data['options']) || !is_array($data['options'])) {
            $this->respond(false, "Missing question fields or options", 400);
        }

        $this->db->beginTransaction();
        try {
            $questionId = $this->questionModel->create(
                intval($data['exam_id']),
                $data['question_text'],
                $data['question_type'] ?? 'mcq',
                floatval($data['marks'] ?? 1.00),
                floatval($data['negative_marks'] ?? 0.00),
                $data['attachment_url'] ?? null
            );

            if (!$questionId) {
                throw new Exception("Failed to insert question");
            }

            foreach ($data['options'] as $opt) {
                if (empty($opt['option_text'])) continue;
                $isCorrect = isset($opt['is_correct']) && ($opt['is_correct'] == 1 || $opt['is_correct'] === true) ? 1 : 0;
                $this->questionModel->addOption($questionId, $opt['option_text'], $isCorrect);
            }

            $this->db->commit();
            $this->respond(true, "Question and options added successfully", 201, ["question_id" => $questionId]);
        } catch (Exception $e) {
            $this->db->rollBack();
            $this->respond(false, "Error: " . $e->getMessage(), 500);
        }
    }

    public function deleteQuestion() {
        AuthMiddleware::authenticate(['teacher']);
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if (!$id) {
            $this->respond(false, "Question ID required", 400);
        }

        if ($this->questionModel->delete($id)) {
            $this->respond(true, "Question deleted successfully", 200);
        } else {
            $this->respond(false, "Failed to delete question", 500);
        }
    }

    public function bulkUploadQuestions() {
        AuthMiddleware::authenticate(['teacher']);
        $exam_id = isset($_POST['exam_id']) ? intval($_POST['exam_id']) : null;

        if (!$exam_id) {
            $this->respond(false, "Exam ID required", 400);
        }

        if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
            $this->respond(false, "Please upload a valid CSV file", 400);
        }

        $fileTmpPath = $_FILES['file']['tmp_name'];
        $handle = fopen($fileTmpPath, "r");
        if ($handle === false) {
            $this->respond(false, "Failed to open CSV file", 500);
        }

        // Read header
        $headers = fgetcsv($handle);
        // Expecting: question_text, question_type, marks, negative_marks, option_1, option_2, option_3, option_4, correct_option_index (1-4)
        
        $this->db->beginTransaction();
        try {
            $uploadedCount = 0;
            while (($row = fgetcsv($handle)) !== false) {
                if (count($row) < 5) continue; // skip invalid empty rows
                
                $question_text = $row[0];
                $question_type = !empty($row[1]) ? $row[1] : 'mcq';
                $marks = !empty($row[2]) ? floatval($row[2]) : 1.00;
                $negative_marks = !empty($row[3]) ? floatval($row[3]) : 0.00;
                
                $questionId = $this->questionModel->create($exam_id, $question_text, $question_type, $marks, $negative_marks);
                if (!$questionId) {
                    throw new Exception("Error inserting question: " . $question_text);
                }

                // Add options (option_1 = col 4, option_2 = col 5, etc.)
                // correct_option_index is the last item (col 8, index 8)
                $correctIndex = isset($row[8]) ? intval($row[8]) : 1;

                for ($i = 1; $i <= 4; $i++) {
                    $optColIndex = 3 + $i; // option_1 is at index 4
                    if (!isset($row[$optColIndex]) || trim($row[$optColIndex]) === '') continue;
                    
                    $isCorrect = ($i === $correctIndex) ? 1 : 0;
                    $this->questionModel->addOption($questionId, $row[$optColIndex], $isCorrect);
                }
                
                $uploadedCount++;
            }
            fclose($handle);
            $this->db->commit();
            $this->respond(true, "Bulk upload completed successfully", 200, ["count" => $uploadedCount]);
        } catch (Exception $e) {
            fclose($handle);
            $this->db->rollBack();
            $this->respond(false, "Error during bulk insert: " . $e->getMessage(), 500);
        }
    }

    public function getExamResults() {
        AuthMiddleware::authenticate(['teacher', 'admin']);
        $exam_id = isset($_GET['exam_id']) ? intval($_GET['exam_id']) : null;

        if (!$exam_id) {
            $this->respond(false, "Exam ID required", 400);
        }

        $results = $this->studentExamModel->getResultsByExam($exam_id);
        $this->respond(true, "Results retrieved successfully", 200, ["results" => $results]);
    }

    public function getTeacherStats() {
        $decoded = AuthMiddleware::authenticate(['teacher']);
        
        // Fetch counters
        $queryExams = "SELECT COUNT(*) as count FROM exams WHERE teacher_id = :id";
        $stmt = $this->db->prepare($queryExams);
        $stmt->execute([':id' => $decoded['id']]);
        $exams = $stmt->fetch()['count'];

        $queryQuestions = "SELECT COUNT(*) as count FROM questions q JOIN exams e ON q.exam_id = e.id WHERE e.teacher_id = :id";
        $stmt = $this->db->prepare($queryQuestions);
        $stmt->execute([':id' => $decoded['id']]);
        $questions = $stmt->fetch()['count'];

        $querySubmissions = "SELECT COUNT(*) as count FROM student_exams se JOIN exams e ON se.exam_id = e.id WHERE e.teacher_id = :id AND se.status = 'submitted'";
        $stmt = $this->db->prepare($querySubmissions);
        $stmt->execute([':id' => $decoded['id']]);
        $submissions = $stmt->fetch()['count'];

        $this->respond(true, "Teacher stats retrieved", 200, [
            "stats" => [
                "exams" => intval($exams),
                "questions" => intval($questions),
                "submissions" => intval($submissions)
            ]
        ]);
    }

    private function respond($success, $message, $code = 200, $data = []) {
        header('Content-Type: application/json');
        http_response_code($code);
        $response = ["success" => $success, "message" => $message];
        if (!empty($data)) {
            $response = array_merge($response, $data);
        }
        echo json_encode($response);
        exit();
    }
}
