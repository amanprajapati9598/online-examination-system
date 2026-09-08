<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt_helper.php';
require_once __DIR__ . '/../Models/User.php';
require_once __DIR__ . '/../Middleware/AuthMiddleware.php';

class AuthController {
    private $db;
    private $user;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->user = new User($this->db);
    }

    public function register() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['name']) || empty($data['email']) || empty($data['password']) || empty($data['role'])) {
            $this->respond(false, "Please provide all required fields (name, email, password, role)", 400);
        }

        if (!in_array($data['role'], ['student', 'teacher'])) {
            $this->respond(false, "Invalid role. Role must be student or teacher", 400);
        }

        if ($this->user->findByEmail($data['email'])) {
            $this->respond(false, "Email address already registered", 400);
        }

        $userId = $this->user->create($data['name'], $data['email'], $data['password'], $data['role']);
        if ($userId) {
            $this->respond(true, "User registered successfully", 201, ["user_id" => $userId]);
        } else {
            $this->respond(false, "Failed to register user", 500);
        }
    }

    public function login() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['email']) || empty($data['password'])) {
            $this->respond(false, "Please provide email and password", 400);
        }

        $userData = $this->user->findByEmail($data['email']);
        if (!$userData) {
            $this->respond(false, "Invalid email or password", 401);
        }

        if ($userData['status'] !== 'active') {
            $this->respond(false, "Account deactivated. Contact administrator", 403);
        }

        if (!password_verify($data['password'], $userData['password'])) {
            $this->respond(false, "Invalid email or password", 401);
        }

        // Generate Token
        $payload = [
            "id" => $userData['id'],
            "name" => $userData['name'],
            "email" => $userData['email'],
            "role" => $userData['role']
        ];
        
        $token = JWTHelper::generateToken($payload);

        $this->respond(true, "Login successful", 200, [
            "token" => $token,
            "user" => [
                "id" => $userData['id'],
                "name" => $userData['name'],
                "email" => $userData['email'],
                "role" => $userData['role'],
                "profile_image" => $userData['profile_image']
            ]
        ]);
    }

    public function forgotPassword() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['email'])) {
            $this->respond(false, "Please provide an email address", 400);
        }

        $userData = $this->user->findByEmail($data['email']);
        if (!$userData) {
            // Act as if it succeeded to prevent email enumeration attacks
            $this->respond(true, "If the email exists, a password reset link has been simulated.", 200);
        }

        // Simulate password reset link
        $resetToken = bin2hex(random_bytes(16));
        $logMessage = "[" . date('Y-m-d H:i:s') . "] Password reset link simulated for " . $data['email'] . ": http://localhost/reset-password?token=" . $resetToken . "\n";
        
        // Write to temp or project file
        file_put_contents(__DIR__ . '/../../public/uploads/email_logs.txt', $logMessage, FILE_APPEND);

        $this->respond(true, "Simulated reset token logged. Check public/uploads/email_logs.txt", 200);
    }

    public function changePassword() {
        $decoded = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['old_password']) || empty($data['new_password'])) {
            $this->respond(false, "Please provide both old and new password", 400);
        }

        $userData = $this->user->findById($decoded['id']);
        // Fetch full profile (including password)
        $query = "SELECT password FROM users WHERE id = :id";
        $stmt = $this->db->prepare($query);
        $stmt->bindParam(':id', $decoded['id']);
        $stmt->execute();
        $fullUser = $stmt->fetch();

        if (!password_verify($data['old_password'], $fullUser['password'])) {
            $this->respond(false, "Current password does not match", 400);
        }

        if ($this->user->changePassword($decoded['id'], $data['new_password'])) {
            $this->respond(true, "Password updated successfully", 200);
        } else {
            $this->respond(false, "Failed to update password", 500);
        }
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
