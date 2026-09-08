<?php
class StudentExam {
    private $conn;
    private $table = "student_exams";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function register($student_id, $exam_id) {
        $query = "INSERT INTO " . $this->table . " (student_id, exam_id, status) VALUES (:student_id, :exam_id, 'registered')
                  ON DUPLICATE KEY UPDATE status = status"; // prevent duplicate errors
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':student_id', $student_id);
        $stmt->bindParam(':exam_id', $exam_id);
        return $stmt->execute();
    }

    public function start($student_id, $exam_id) {
        // Find existing session
        $query = "SELECT * FROM " . $this->table . " WHERE student_id = :student_id AND exam_id = :exam_id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':student_id', $student_id);
        $stmt->bindParam(':exam_id', $exam_id);
        $stmt->execute();
        $session = $stmt->fetch();

        if (!$session) {
            // Create a new session and start it
            $query = "INSERT INTO " . $this->table . " (student_id, exam_id, status, start_time) VALUES (:student_id, :exam_id, 'ongoing', NOW())";
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':student_id', $student_id);
            $stmt->bindParam(':exam_id', $exam_id);
            $stmt->execute();
            return $this->conn->lastInsertId();
        } else {
            if ($session['status'] === 'registered') {
                $query = "UPDATE " . $this->table . " SET status = 'ongoing', start_time = NOW() WHERE id = :id";
                $stmt = $this->conn->prepare($query);
                $stmt->bindParam(':id', $session['id']);
                $stmt->execute();
            }
            return $session['id'];
        }
    }

    public function findById($id) {
        $query = "SELECT se.*, e.title as exam_title, e.duration_minutes, e.total_marks, e.passing_marks, e.anti_cheating_enabled, u.name as student_name 
                  FROM " . $this->table . " se
                  JOIN exams e ON se.exam_id = e.id
                  JOIN users u ON se.student_id = u.id
                  WHERE se.id = :id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        return $stmt->fetch();
    }

    public function findByStudentAndExam($student_id, $exam_id) {
        $query = "SELECT * FROM " . $this->table . " WHERE student_id = :student_id AND exam_id = :exam_id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':student_id', $student_id);
        $stmt->bindParam(':exam_id', $exam_id);
        $stmt->execute();
        return $stmt->fetch();
    }

    public function saveAnswer($student_exam_id, $question_id, $selected_option_id) {
        // Fetch option correctness and question marks
        $query = "SELECT is_correct FROM question_options WHERE id = :option_id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':option_id', $selected_option_id);
        $stmt->execute();
        $option = $stmt->fetch();
        
        $is_correct = ($option && $option['is_correct'] == 1) ? 1 : 0;

        $query = "SELECT marks, negative_marks, exam_id FROM questions WHERE id = :question_id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':question_id', $question_id);
        $stmt->execute();
        $qData = $stmt->fetch();

        $marks_obtained = 0.00;
        if ($is_correct) {
            $marks_obtained = $qData ? (float)$qData['marks'] : 1.00;
        } else {
            // Apply exam level negative marking if specific question has no specific negative marks
            if ($qData) {
                if ((float)$qData['negative_marks'] > 0) {
                    $marks_obtained = -1 * (float)$qData['negative_marks'];
                } else {
                    // Check exam negative marking factor
                    $query = "SELECT negative_marking_factor, total_marks FROM exams WHERE id = :exam_id LIMIT 1";
                    $stmt = $this->conn->prepare($query);
                    $stmt->bindParam(':exam_id', $qData['exam_id']);
                    $stmt->execute();
                    $exam = $stmt->fetch();
                    if ($exam && (float)$exam['negative_marking_factor'] > 0) {
                        $marks_obtained = -1 * ((float)$qData['marks'] * (float)$exam['negative_marking_factor']);
                    }
                }
            }
        }

        // Insert or update answer
        $query = "INSERT INTO student_answers (student_exam_id, question_id, selected_option_id, is_correct, marks_obtained) 
                  VALUES (:student_exam_id, :question_id, :selected_option_id, :is_correct, :marks_obtained)
                  ON DUPLICATE KEY UPDATE 
                  selected_option_id = :selected_option_id, 
                  is_correct = :is_correct, 
                  marks_obtained = :marks_obtained";
                  
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':student_exam_id', $student_exam_id);
        $stmt->bindParam(':question_id', $question_id);
        $stmt->bindParam(':selected_option_id', $selected_option_id);
        $stmt->bindParam(':is_correct', $is_correct);
        $stmt->bindParam(':marks_obtained', $marks_obtained);
        return $stmt->execute();
    }

    public function logCheatingEvent($student_exam_id, $event_type, $details = '') {
        // Insert event log
        $query = "INSERT INTO cheating_logs (student_exam_id, event_type, details) VALUES (:student_exam_id, :event_type, :details)";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':student_exam_id', $student_exam_id);
        $stmt->bindParam(':event_type', $event_type);
        $stmt->bindParam(':details', $details);
        $stmt->execute();

        // Increment counter in student_exams
        if ($event_type === 'tab_switch') {
            $query = "UPDATE " . $this->table . " SET tab_switches_count = tab_switches_count + 1 WHERE id = :id";
        } elseif ($event_type === 'fullscreen_exit') {
            $query = "UPDATE " . $this->table . " SET fullscreen_exits_count = fullscreen_exits_count + 1 WHERE id = :id";
        } else {
            return true;
        }
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $student_exam_id);
        return $stmt->execute();
    }

    public function submit($id, $auto_submitted = 0) {
        // Calculate total score from answers
        $query = "SELECT SUM(marks_obtained) as total_score FROM student_answers WHERE student_exam_id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $result = $stmt->fetch();
        $score = $result['total_score'] !== null ? (float)$result['total_score'] : 0.00;
        
        // Ensure score doesn't drop below 0 if negative marking is harsh
        if ($score < 0) {
            $score = 0.00;
        }

        // Complete exam session
        $query = "UPDATE " . $this->table . " SET status = 'submitted', submit_time = NOW(), score = :score, auto_submitted = :auto_submitted WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->bindParam(':score', $score);
        $stmt->bindParam(':auto_submitted', $auto_submitted);
        return $stmt->execute();
    }

    public function getActiveExamsForMonitoring() {
        $query = "SELECT se.id as session_id, se.start_time, se.tab_switches_count, se.fullscreen_exits_count, se.status,
                  u.name as student_name, u.email as student_email,
                  e.title as exam_title, e.duration_minutes
                  FROM " . $this->table . " se
                  JOIN users u ON se.student_id = u.id
                  JOIN exams e ON se.exam_id = e.id
                  WHERE se.status = 'ongoing'
                  ORDER BY se.start_time DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function getAnswersBySession($student_exam_id) {
        $query = "SELECT sa.*, q.question_text, q.question_type, q.marks as q_marks, qo.option_text as selected_option_text
                  FROM student_answers sa
                  JOIN questions q ON sa.question_id = q.id
                  LEFT JOIN question_options qo ON sa.selected_option_id = qo.id
                  WHERE sa.student_exam_id = :student_exam_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':student_exam_id', $student_exam_id);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function getResultsByExam($exam_id) {
        $query = "SELECT se.*, u.name as student_name, u.email as student_email 
                  FROM " . $this->table . " se 
                  JOIN users u ON se.student_id = u.id 
                  WHERE se.exam_id = :exam_id AND se.status = 'submitted' 
                  ORDER BY se.score DESC, se.submit_time ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':exam_id', $exam_id);
        $stmt->execute();
        return $stmt->fetchAll();
    }
}
