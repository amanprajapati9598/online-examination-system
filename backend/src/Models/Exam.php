<?php
class Exam {
    private $conn;
    private $table = "exams";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create($title, $description, $subject_id, $teacher_id, $duration_minutes, $start_time, $end_time, $total_marks, $passing_marks, $negative_marking_factor, $randomize_questions, $randomize_options, $anti_cheating_enabled, $is_published) {
        $qr_code_token = uniqid('exam_', true);
        
        $query = "INSERT INTO " . $this->table . " (title, description, subject_id, teacher_id, duration_minutes, start_time, end_time, total_marks, passing_marks, negative_marking_factor, randomize_questions, randomize_options, anti_cheating_enabled, is_published, qr_code_token) 
                  VALUES (:title, :description, :subject_id, :teacher_id, :duration_minutes, :start_time, :end_time, :total_marks, :passing_marks, :negative_marking_factor, :randomize_questions, :randomize_options, :anti_cheating_enabled, :is_published, :qr_code_token)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':title', $title);
        $stmt->bindParam(':description', $description);
        $stmt->bindParam(':subject_id', $subject_id);
        $stmt->bindParam(':teacher_id', $teacher_id);
        $stmt->bindParam(':duration_minutes', $duration_minutes);
        $stmt->bindParam(':start_time', $start_time);
        $stmt->bindParam(':end_time', $end_time);
        $stmt->bindParam(':total_marks', $total_marks);
        $stmt->bindParam(':passing_marks', $passing_marks);
        $stmt->bindParam(':negative_marking_factor', $negative_marking_factor);
        $stmt->bindParam(':randomize_questions', $randomize_questions);
        $stmt->bindParam(':randomize_options', $randomize_options);
        $stmt->bindParam(':anti_cheating_enabled', $anti_cheating_enabled);
        $stmt->bindParam(':is_published', $is_published);
        $stmt->bindParam(':qr_code_token', $qr_code_token);
        
        if ($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    public function update($id, $title, $description, $subject_id, $duration_minutes, $start_time, $end_time, $total_marks, $passing_marks, $negative_marking_factor, $randomize_questions, $randomize_options, $anti_cheating_enabled, $is_published) {
        $query = "UPDATE " . $this->table . " SET 
                  title = :title, 
                  description = :description, 
                  subject_id = :subject_id, 
                  duration_minutes = :duration_minutes, 
                  start_time = :start_time, 
                  end_time = :end_time, 
                  total_marks = :total_marks, 
                  passing_marks = :passing_marks, 
                  negative_marking_factor = :negative_marking_factor, 
                  randomize_questions = :randomize_questions, 
                  randomize_options = :randomize_options, 
                  anti_cheating_enabled = :anti_cheating_enabled, 
                  is_published = :is_published 
                  WHERE id = :id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->bindParam(':title', $title);
        $stmt->bindParam(':description', $description);
        $stmt->bindParam(':subject_id', $subject_id);
        $stmt->bindParam(':duration_minutes', $duration_minutes);
        $stmt->bindParam(':start_time', $start_time);
        $stmt->bindParam(':end_time', $end_time);
        $stmt->bindParam(':total_marks', $total_marks);
        $stmt->bindParam(':passing_marks', $passing_marks);
        $stmt->bindParam(':negative_marking_factor', $negative_marking_factor);
        $stmt->bindParam(':randomize_questions', $randomize_questions);
        $stmt->bindParam(':randomize_options', $randomize_options);
        $stmt->bindParam(':anti_cheating_enabled', $anti_cheating_enabled);
        $stmt->bindParam(':is_published', $is_published);
        
        return $stmt->execute();
    }

    public function delete($id) {
        $query = "DELETE FROM " . $this->table . " WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        return $stmt->execute();
    }

    public function findById($id) {
        $query = "SELECT e.*, s.name as subject_name, u.name as teacher_name FROM " . $this->table . " e 
                  JOIN subjects s ON e.subject_id = s.id 
                  JOIN users u ON e.teacher_id = u.id 
                  WHERE e.id = :id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        return $stmt->fetch();
    }

    public function findByQRToken($token) {
        $query = "SELECT e.*, s.name as subject_name FROM " . $this->table . " e 
                  JOIN subjects s ON e.subject_id = s.id 
                  WHERE e.qr_code_token = :token LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':token', $token);
        $stmt->execute();
        return $stmt->fetch();
    }

    public function getByTeacher($teacher_id) {
        $query = "SELECT e.*, s.name as subject_name, 
                  (SELECT COUNT(*) FROM questions q WHERE q.exam_id = e.id) as question_count 
                  FROM " . $this->table . " e 
                  JOIN subjects s ON e.subject_id = s.id 
                  WHERE e.teacher_id = :teacher_id 
                  ORDER BY e.start_time DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':teacher_id', $teacher_id);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function getAvailableForStudent($student_id) {
        // Return published exams that are either ongoing or upcoming, AND student has not completed.
        // Also show registration status.
        $query = "SELECT e.*, s.name as subject_name, u.name as teacher_name, se.status as attempt_status, se.score
                  FROM " . $this->table . " e
                  JOIN subjects s ON e.subject_id = s.id
                  JOIN users u ON e.teacher_id = u.id
                  LEFT JOIN student_exams se ON se.exam_id = e.id AND se.student_id = :student_id
                  WHERE e.is_published = 1 AND e.end_time > NOW()
                  ORDER BY e.start_time ASC";
                  
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':student_id', $student_id);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function getHistoryForStudent($student_id) {
        // Completed/Submitted exams by student
        $query = "SELECT e.*, s.name as subject_name, u.name as teacher_name, se.status as attempt_status, se.score, se.start_time as attempt_start, se.submit_time as attempt_submit
                  FROM student_exams se
                  JOIN exams e ON se.exam_id = e.id
                  JOIN subjects s ON e.subject_id = s.id
                  JOIN users u ON e.teacher_id = u.id
                  WHERE se.student_id = :student_id AND se.status IN ('submitted', 'abandoned')
                  ORDER BY se.submit_time DESC";
                  
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':student_id', $student_id);
        $stmt->execute();
        return $stmt->fetchAll();
    }
}
