<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../Models/User.php';
require_once __DIR__ . '/../Models/Course.php';
require_once __DIR__ . '/../Models/Subject.php';
require_once __DIR__ . '/../Models/StudentExam.php';
require_once __DIR__ . '/../Middleware/AuthMiddleware.php';

class AdminController {
    private $db;
    private $userModel;
    private $courseModel;
    private $subjectModel;
    private $studentExamModel;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->userModel = new User($this->db);
        $this->courseModel = new Course($this->db);
        $this->subjectModel = new Subject($this->db);
        $this->studentExamModel = new StudentExam($this->db);
    }

    public function getUsers() {
        AuthMiddleware::authenticate(['admin']);
        $role = isset($_GET['role']) ? $_GET['role'] : null;
        $search = isset($_GET['search']) ? $_GET['search'] : null;
        
        $users = $this->userModel->getAll($role, $search);
        $this->respond(true, "Users retrieved successfully", 200, ["users" => $users]);
    }

    public function createUser() {
        AuthMiddleware::authenticate(['admin']);
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['name']) || empty($data['email']) || empty($data['password']) || empty($data['role'])) {
            $this->respond(false, "Please provide all required fields (name, email, password, role)", 400);
        }

        if ($this->userModel->findByEmail($data['email'])) {
            $this->respond(false, "Email address already registered", 400);
        }

        $userId = $this->userModel->create($data['name'], $data['email'], $data['password'], $data['role']);
        if ($userId) {
            $this->respond(true, "User created successfully", 201, ["user_id" => $userId]);
        } else {
            $this->respond(false, "Failed to create user", 500);
        }
    }

    public function updateUser() {
        AuthMiddleware::authenticate(['admin']);
        $data = json_decode(file_get_contents("php://input"), true);
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if (!$id || empty($data['name']) || empty($data['email']) || empty($data['status'])) {
            $this->respond(false, "Invalid parameter or missing data", 400);
        }

        $role = isset($data['role']) ? $data['role'] : null;

        if ($this->userModel->update($id, $data['name'], $data['email'], $data['status'], $role)) {
            $this->respond(true, "User updated successfully", 200);
        } else {
            $this->respond(false, "Failed to update user", 500);
        }
    }

    public function deleteUser() {
        AuthMiddleware::authenticate(['admin']);
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;

        if (!$id) {
            $this->respond(false, "Missing user ID", 400);
        }

        if ($this->userModel->delete($id)) {
            $this->respond(true, "User deleted successfully", 200);
        } else {
            $this->respond(false, "Failed to delete user", 500);
        }
    }

    public function getCourses() {
        AuthMiddleware::authenticate(['admin', 'teacher']);
        $courses = $this->courseModel->getAll();
        $this->respond(true, "Courses retrieved successfully", 200, ["courses" => $courses]);
    }

    public function createCourse() {
        AuthMiddleware::authenticate(['admin']);
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['name']) || empty($data['code'])) {
            $this->respond(false, "Please provide course name and code", 400);
        }

        $courseId = $this->courseModel->create($data['name'], $data['code'], $data['description'] ?? '');
        if ($courseId) {
            $this->respond(true, "Course created successfully", 201, ["course_id" => $courseId]);
        } else {
            $this->respond(false, "Failed to create course", 500);
        }
    }

    public function getSubjects() {
        AuthMiddleware::authenticate(['admin', 'teacher', 'student']);
        $course_id = isset($_GET['course_id']) ? intval($_GET['course_id']) : null;
        
        if ($course_id) {
            $subjects = $this->subjectModel->getByCourse($course_id);
        } else {
            $subjects = $this->subjectModel->getAll();
        }
        $this->respond(true, "Subjects retrieved successfully", 200, ["subjects" => $subjects]);
    }

    public function createSubject() {
        AuthMiddleware::authenticate(['admin']);
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['course_id']) || empty($data['name']) || empty($data['code'])) {
            $this->respond(false, "Please provide course_id, subject name and code", 400);
        }

        $subjId = $this->subjectModel->create($data['course_id'], $data['name'], $data['code'], $data['description'] ?? '');
        if ($subjId) {
            $this->respond(true, "Subject created successfully", 201, ["subject_id" => $subjId]);
        } else {
            $this->respond(false, "Failed to create subject", 500);
        }
    }

    public function monitorActiveExams() {
        AuthMiddleware::authenticate(['admin', 'teacher']);
        $activeExams = $this->studentExamModel->getActiveExamsForMonitoring();
        $this->respond(true, "Active exams retrieved successfully", 200, ["active_exams" => $activeExams]);
    }

    public function getSystemStats() {
        AuthMiddleware::authenticate(['admin']);

        // Fetch counts from database
        $queries = [
            "students" => "SELECT COUNT(*) as count FROM users WHERE role = 'student'",
            "teachers" => "SELECT COUNT(*) as count FROM users WHERE role = 'teacher'",
            "exams" => "SELECT COUNT(*) as count FROM exams",
            "subjects" => "SELECT COUNT(*) as count FROM subjects",
            "courses" => "SELECT COUNT(*) as count FROM courses",
            "active_exams" => "SELECT COUNT(*) as count FROM student_exams WHERE status = 'ongoing'"
        ];

        $stats = [];
        foreach ($queries as $key => $sql) {
            $stmt = $this->db->query($sql);
            $res = $stmt->fetch();
            $stats[$key] = intval($res['count']);
        }

        $this->respond(true, "Stats retrieved successfully", 200, ["stats" => $stats]);
    }

    public function getSystemSettings() {
        AuthMiddleware::authenticate(['admin']);
        $query = "SELECT * FROM system_settings";
        $stmt = $this->db->query($query);
        $settings = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);
        $this->respond(true, "Settings retrieved successfully", 200, ["settings" => $settings]);
    }

    public function updateSystemSettings() {
        AuthMiddleware::authenticate(['admin']);
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data) || !is_array($data)) {
            $this->respond(false, "Invalid payload", 400);
        }

        $query = "INSERT INTO system_settings (setting_key, setting_value) VALUES (:key, :value) 
                  ON DUPLICATE KEY UPDATE setting_value = :value";
        $stmt = $this->db->prepare($query);

        foreach ($data as $key => $value) {
            $stmt->execute([':key' => $key, ':value' => strval($value)]);
        }

        $this->respond(true, "Settings updated successfully", 200);
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
