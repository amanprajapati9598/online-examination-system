<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../Models/Exam.php';
require_once __DIR__ . '/../Models/Question.php';
require_once __DIR__ . '/../Models/StudentExam.php';
require_once __DIR__ . '/../Middleware/AuthMiddleware.php';

class StudentController {
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

    public function getAvailableExams() {
        $decoded = AuthMiddleware::authenticate(['student']);
        $exams = $this->examModel->getAvailableForStudent($decoded['id']);
        $this->respond(true, "Available exams retrieved", 200, ["exams" => $exams]);
    }

    public function registerForExam() {
        $decoded = AuthMiddleware::authenticate(['student']);
        $data = json_decode(file_get_contents("php://input"), true);
        $exam_id = null;

        // Support standard registration or QR-code based registration
        if (!empty($data['qr_token'])) {
            $exam = $this->examModel->findByQRToken($data['qr_token']);
            if (!$exam) {
                $this->respond(false, "Invalid QR exam code", 404);
            }
            $exam_id = $exam['id'];
        } elseif (!empty($data['exam_id'])) {
            $exam_id = intval($data['exam_id']);
        } else {
            $this->respond(false, "Exam ID or QR code token is required", 400);
        }

        // Verify exam hasn't ended
        $exam = $this->examModel->findById($exam_id);
        if (!$exam) {
            $this->respond(false, "Exam not found", 404);
        }

        if (strtotime($exam['end_time']) < time()) {
            $this->respond(false, "Exam registration has closed", 400);
        }

        if ($this->studentExamModel->register($decoded['id'], $exam_id)) {
            $this->respond(true, "Registered for exam successfully", 200, ["exam_id" => $exam_id]);
        } else {
            $this->respond(false, "Failed to register for exam", 500);
        }
    }

    public function startExam() {
        $decoded = AuthMiddleware::authenticate(['student']);
        $data = json_decode(file_get_contents("php://input"), true);
        $exam_id = isset($data['exam_id']) ? intval($data['exam_id']) : null;

        if (!$exam_id) {
            $this->respond(false, "Exam ID required", 400);
        }

        $exam = $this->examModel->findById($exam_id);
        if (!$exam) {
            $this->respond(false, "Exam not found", 404);
        }

        // Verify current time is between start_time and end_time
        $now = time();
        $startTime = strtotime($exam['start_time']);
        $endTime = strtotime($exam['end_time']);

        if ($now < $startTime) {
            $this->respond(false, "Exam has not started yet. Starts at " . $exam['start_time'], 400);
        }
        if ($now > $endTime) {
            $this->respond(false, "Exam has already ended", 400);
        }

        // Initialize exam attempt session
        $attemptId = $this->studentExamModel->start($decoded['id'], $exam_id);
        if (!$attemptId) {
            $this->respond(false, "Failed to initialize exam session", 500);
        }

        // Fetch questions, checking configuration for randomization
        $questions = $this->questionModel->getByExam($exam_id, $exam['randomize_questions'], $exam['randomize_options']);

        // Return details
        $this->respond(true, "Exam session started", 200, [
            "student_exam_id" => $attemptId,
            "duration_minutes" => $exam['duration_minutes'],
            "anti_cheating_enabled" => $exam['anti_cheating_enabled'],
            "questions" => $questions
        ]);
    }

    public function saveAnswer() {
        $decoded = AuthMiddleware::authenticate(['student']);
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['student_exam_id']) || empty($data['question_id']) || !isset($data['selected_option_id'])) {
            $this->respond(false, "Missing session ID, question ID, or answer choice", 400);
        }

        // Verify session belongs to student and is ongoing
        $session = $this->studentExamModel->findById(intval($data['student_exam_id']));
        if (!$session || $session['student_id'] != $decoded['id'] || $session['status'] !== 'ongoing') {
            $this->respond(false, "Unauthorized or inactive exam session", 403);
        }

        $success = $this->studentExamModel->saveAnswer(
            intval($data['student_exam_id']),
            intval($data['question_id']),
            intval($data['selected_option_id'])
        );

        if ($success) {
            $this->respond(true, "Answer saved", 200);
        } else {
            $this->respond(false, "Failed to autosave answer", 500);
        }
    }

    public function logCheating() {
        $decoded = AuthMiddleware::authenticate(['student']);
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['student_exam_id']) || empty($data['event_type'])) {
            $this->respond(false, "Missing session ID or cheating event type", 400);
        }

        $session = $this->studentExamModel->findById(intval($data['student_exam_id']));
        if (!$session || $session['student_id'] != $decoded['id'] || $session['status'] !== 'ongoing') {
            $this->respond(false, "Unauthorized or inactive exam session", 403);
        }

        $success = $this->studentExamModel->logCheatingEvent(
            intval($data['student_exam_id']),
            $data['event_type'],
            $data['details'] ?? ''
        );

        if ($success) {
            $this->respond(true, "Incident logged successfully", 200);
        } else {
            $this->respond(false, "Failed to log event", 500);
        }
    }

    public function submitExam() {
        $decoded = AuthMiddleware::authenticate(['student']);
        $data = json_decode(file_get_contents("php://input"), true);
        $student_exam_id = isset($data['student_exam_id']) ? intval($data['student_exam_id']) : null;

        if (!$student_exam_id) {
            $this->respond(false, "Student exam session ID required", 400);
        }

        $session = $this->studentExamModel->findById($student_exam_id);
        if (!$session || $session['student_id'] != $decoded['id']) {
            $this->respond(false, "Unauthorized session", 403);
        }

        if ($session['status'] === 'submitted') {
            $this->respond(true, "Exam was already submitted", 200, [
                "score" => $session['score']
            ]);
        }

        $autoSubmitted = isset($data['auto_submitted']) && $data['auto_submitted'] ? 1 : 0;
        
        if ($this->studentExamModel->submit($student_exam_id, $autoSubmitted)) {
            // Retrieve calculated score
            $updatedSession = $this->studentExamModel->findById($student_exam_id);
            $this->respond(true, "Exam submitted successfully", 200, [
                "score" => $updatedSession['score'],
                "passing_marks" => $updatedSession['passing_marks'],
                "total_marks" => $updatedSession['total_marks']
            ]);
        } else {
            $this->respond(false, "Failed to submit exam", 500);
        }
    }

    public function getExamHistory() {
        $decoded = AuthMiddleware::authenticate(['student']);
        $history = $this->examModel->getHistoryForStudent($decoded['id']);
        $this->respond(true, "Exam history retrieved", 200, ["history" => $history]);
    }

    public function getResultDetails() {
        $decoded = AuthMiddleware::authenticate(['student', 'teacher', 'admin']);
        $student_exam_id = isset($_GET['student_exam_id']) ? intval($_GET['student_exam_id']) : null;

        if (!$student_exam_id) {
            $this->respond(false, "Student exam session ID required", 400);
        }

        $session = $this->studentExamModel->findById($student_exam_id);
        if (!$session) {
            $this->respond(false, "Session not found", 404);
        }

        // Secure access control: students can only see their own results
        if ($decoded['role'] === 'student' && $session['student_id'] != $decoded['id']) {
            $this->respond(false, "Access denied", 403);
        }

        $answers = $this->studentExamModel->getAnswersBySession($student_exam_id);
        $this->respond(true, "Result details retrieved", 200, [
            "session" => $session,
            "answers" => $answers
        ]);
    }

    public function getStudentAnalytics() {
        $decoded = AuthMiddleware::authenticate(['student']);
        $student_id = $decoded['id'];

        // Get analytical overview
        $queryCounts = "SELECT 
                        COUNT(id) as total_exams,
                        SUM(CASE WHEN score >= (SELECT passing_marks FROM exams WHERE id = student_exams.exam_id) THEN 1 ELSE 0 END) as passed_exams,
                        AVG(score) as average_score
                        FROM student_exams 
                        WHERE student_id = :id AND status = 'submitted'";
                        
        $stmt = $this->db->prepare($queryCounts);
        $stmt->execute([':id' => $student_id]);
        $summary = $stmt->fetch();

        // Get details for line chart: score progression
        $queryProgression = "SELECT se.score, e.title as exam_title, se.submit_time
                             FROM student_exams se
                             JOIN exams e ON se.exam_id = e.id
                             WHERE se.student_id = :id AND se.status = 'submitted'
                             ORDER BY se.submit_time ASC";
        $stmt = $this->db->prepare($queryProgression);
        $stmt->execute([':id' => $student_id]);
        $progression = $stmt->fetchAll();

        // Get leaderboard: top students in system
        $queryLeaderboard = "SELECT u.name, SUM(se.score) as total_points, COUNT(se.id) as exams_taken
                             FROM student_exams se
                             JOIN users u ON se.student_id = u.id
                             WHERE se.status = 'submitted'
                             GROUP BY se.student_id
                             ORDER BY total_points DESC LIMIT 10";
        $stmt = $this->db->query($queryLeaderboard);
        $leaderboard = $stmt->fetchAll();

        $this->respond(true, "Student analytics retrieved", 200, [
            "summary" => [
                "total_exams" => intval($summary['total_exams']),
                "passed_exams" => intval($summary['passed_exams']),
                "failed_exams" => intval($summary['total_exams']) - intval($summary['passed_exams']),
                "average_score" => round(floatval($summary['average_score']), 2)
            ],
            "progression" => $progression,
            "leaderboard" => $leaderboard
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
