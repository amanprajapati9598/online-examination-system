<?php
class Subject {
    private $conn;
    private $table = "subjects";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create($course_id, $name, $code, $description) {
        $query = "INSERT INTO " . $this->table . " (course_id, name, code, description) VALUES (:course_id, :name, :code, :description)";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':course_id', $course_id);
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':code', $code);
        $stmt->bindParam(':description', $description);
        
        if ($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    public function getAll() {
        $query = "SELECT s.*, c.name as course_name FROM " . $this->table . " s 
                  JOIN courses c ON s.course_id = c.id 
                  ORDER BY s.name ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function getByCourse($course_id) {
        $query = "SELECT * FROM " . $this->table . " WHERE course_id = :course_id ORDER BY name ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':course_id', $course_id);
        $stmt->execute();
        return $stmt->fetchAll();
    }
}
