<?php
class Question {
    private $conn;
    private $table = "questions";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create($exam_id, $question_text, $question_type, $marks, $negative_marks, $attachment_url = null) {
        $query = "INSERT INTO " . $this->table . " (exam_id, question_text, question_type, marks, negative_marks, attachment_url) 
                  VALUES (:exam_id, :question_text, :question_type, :marks, :negative_marks, :attachment_url)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':exam_id', $exam_id);
        $stmt->bindParam(':question_text', $question_text);
        $stmt->bindParam(':question_type', $question_type);
        $stmt->bindParam(':marks', $marks);
        $stmt->bindParam(':negative_marks', $negative_marks);
        $stmt->bindParam(':attachment_url', $attachment_url);
        
        if ($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    public function delete($id) {
        $query = "DELETE FROM " . $this->table . " WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        return $stmt->execute();
    }

    public function addOption($question_id, $option_text, $is_correct) {
        $query = "INSERT INTO question_options (question_id, option_text, is_correct) VALUES (:question_id, :option_text, :is_correct)";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':question_id', $question_id);
        $stmt->bindParam(':option_text', $option_text);
        $stmt->bindParam(':is_correct', $is_correct);
        return $stmt->execute();
    }

    public function clearOptions($question_id) {
        $query = "DELETE FROM question_options WHERE question_id = :question_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':question_id', $question_id);
        return $stmt->execute();
    }

    public function getByExam($exam_id, $randomizeQuestions = false, $randomizeOptions = false) {
        $query = "SELECT * FROM " . $this->table . " WHERE exam_id = :exam_id";
        if ($randomizeQuestions) {
            $query .= " ORDER BY RAND()";
        } else {
            $query .= " ORDER BY id ASC";
        }

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':exam_id', $exam_id);
        $stmt->execute();
        $questions = $stmt->fetchAll();

        foreach ($questions as &$q) {
            $q['options'] = $this->getOptions($q['id'], $randomizeOptions);
        }

        return $questions;
    }

    public function getOptions($question_id, $randomize = false) {
        $query = "SELECT id, option_text, is_correct FROM question_options WHERE question_id = :question_id";
        if ($randomize) {
            $query .= " ORDER BY RAND()";
        } else {
            $query .= " ORDER BY id ASC";
        }

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':question_id', $question_id);
        $stmt->execute();
        return $stmt->fetchAll();
    }
}
