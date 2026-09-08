<?php
require_once __DIR__ . '/../../config/jwt_helper.php';

class AuthMiddleware {
    public static function authenticate($allowedRoles = []) {
        $headers = getallheaders();
        $authHeader = null;

        foreach ($headers as $key => $value) {
            if (strcasecmp($key, 'Authorization') === 0) {
                $authHeader = $value;
                break;
            }
        }

        if (!$authHeader) {
            self::respondError("Authorization header not found", 401);
        }

        $parts = explode(" ", $authHeader);
        if (count($parts) !== 2 || strcasecmp($parts[0], 'Bearer') !== 0) {
            self::respondError("Invalid Authorization format. Use Bearer <token>", 401);
        }

        $token = $parts[1];
        $decoded = JWTHelper::decodeToken($token);

        if (!$decoded) {
            self::respondError("Invalid or expired authentication token", 401);
        }

        // Check if role is allowed
        if (!empty($allowedRoles) && !in_array($decoded['role'], $allowedRoles)) {
            self::respondError("Access denied. Insufficient permissions", 403);
        }

        return $decoded;
    }

    private static function respondError($message, $code) {
        header('Content-Type: application/json');
        http_response_code($code);
        echo json_encode([
            "success" => false,
            "message" => $message
        ]);
        exit();
    }
}
