<?php
// CORS Headers Setup
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

// Preflight CORS request termination
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// Autoload controllers and models
require_once __DIR__ . '/../src/Controllers/AuthController.php';
require_once __DIR__ . '/../src/Controllers/AdminController.php';
require_once __DIR__ . '/../src/Controllers/TeacherController.php';
require_once __DIR__ . '/../src/Controllers/StudentController.php';
require_once __DIR__ . '/../src/Controllers/ReportController.php';

// Parse Request URI
$requestUri = $_SERVER['REQUEST_URI'];
$requestUri = explode('?', $requestUri)[0]; // Remove query params

// Standardize route relative to api/ directory
// Find where "/api" occurs and grab everything after it
$apiPath = "";
$apiIndex = strpos($requestUri, '/api');
if ($apiIndex !== false) {
    $apiPath = substr($requestUri, $apiIndex + 4);
} else {
    // If accessed directly without rewrite, parse relative to index.php
    $scriptIndex = strpos($requestUri, 'index.php');
    if ($scriptIndex !== false) {
        $apiPath = substr($requestUri, $scriptIndex + 9);
    }
}

// Remove trailing slash
$apiPath = rtrim($apiPath, '/');
$method = $_SERVER['REQUEST_METHOD'];

// Route dispatcher
try {
    switch ($apiPath) {
        // --- AUTH ROUTES ---
        case '/auth/register':
            if ($method === 'POST') {
                (new AuthController())->register();
            }
            break;
        case '/auth/login':
            if ($method === 'POST') {
                (new AuthController())->login();
            }
            break;
        case '/auth/forgot-password':
            if ($method === 'POST') {
                (new AuthController())->forgotPassword();
            }
            break;
        case '/auth/change-password':
            if ($method === 'POST') {
                (new AuthController())->changePassword();
            }
            break;

        // --- ADMIN ROUTES ---
        case '/admin/users':
            $admin = new AdminController();
            if ($method === 'GET') {
                $admin->getUsers();
            } elseif ($method === 'POST') {
                $admin->createUser();
            } elseif ($method === 'PUT') {
                $admin->updateUser();
            } elseif ($method === 'DELETE') {
                $admin->deleteUser();
            }
            break;
        case '/admin/courses':
            $admin = new AdminController();
            if ($method === 'GET') {
                $admin->getCourses();
            } elseif ($method === 'POST') {
                $admin->createCourse();
            }
            break;
        case '/admin/subjects':
            $admin = new AdminController();
            if ($method === 'GET') {
                $admin->getSubjects();
            } elseif ($method === 'POST') {
                $admin->createSubject();
            }
            break;
        case '/admin/exams/active':
            if ($method === 'GET') {
                (new AdminController())->monitorActiveExams();
            }
            break;
        case '/admin/stats':
            if ($method === 'GET') {
                (new AdminController())->getSystemStats();
            }
            break;
        case '/admin/settings':
            $admin = new AdminController();
            if ($method === 'GET') {
                $admin->getSystemSettings();
            } elseif ($method === 'POST') {
                $admin->updateSystemSettings();
            }
            break;

        // --- TEACHER ROUTES ---
        case '/teacher/exams':
            $teacher = new TeacherController();
            if ($method === 'GET') {
                if (isset($_GET['id'])) {
                    $teacher->getExamDetails();
                } else {
                    $teacher->getExams();
                }
            } elseif ($method === 'POST') {
                $teacher->createExam();
            } elseif ($method === 'PUT') {
                $teacher->updateExam();
            } elseif ($method === 'DELETE') {
                $teacher->deleteExam();
            }
            break;
        case '/teacher/questions':
            $teacher = new TeacherController();
            if ($method === 'GET') {
                $teacher->getQuestions();
            } elseif ($method === 'POST') {
                $teacher->addQuestion();
            } elseif ($method === 'DELETE') {
                $teacher->deleteQuestion();
            }
            break;
        case '/teacher/questions/bulk':
            if ($method === 'POST') {
                (new TeacherController())->bulkUploadQuestions();
            }
            break;
        case '/teacher/results':
            if ($method === 'GET') {
                (new TeacherController())->getExamResults();
            }
            break;
        case '/teacher/stats':
            if ($method === 'GET') {
                (new TeacherController())->getTeacherStats();
            }
            break;

        // --- STUDENT ROUTES ---
        case '/student/exams/available':
            if ($method === 'GET') {
                (new StudentController())->getAvailableExams();
            }
            break;
        case '/student/exams/register':
            if ($method === 'POST') {
                (new StudentController())->registerForExam();
            }
            break;
        case '/student/exams/start':
            if ($method === 'POST') {
                (new StudentController())->startExam();
            }
            break;
        case '/student/exams/save-answer':
            if ($method === 'POST') {
                (new StudentController())->saveAnswer();
            }
            break;
        case '/student/exams/cheating-log':
            if ($method === 'POST') {
                (new StudentController())->logCheating();
            }
            break;
        case '/student/exams/submit':
            if ($method === 'POST') {
                (new StudentController())->submitExam();
            }
            break;
        case '/student/exams/history':
            if ($method === 'GET') {
                (new StudentController())->getExamHistory();
            }
            break;
        case '/student/exams/result':
            if ($method === 'GET') {
                (new StudentController())->getResultDetails();
            }
            break;
        case '/student/analytics':
            if ($method === 'GET') {
                (new StudentController())->getStudentAnalytics();
            }
            break;

        // --- REPORT ROUTES ---
        case '/reports/result/download':
            if ($method === 'GET') {
                (new ReportController())->downloadResultPDF();
            }
            break;
        case '/reports/results/export':
            if ($method === 'GET') {
                (new ReportController())->exportResultsCSV();
            }
            break;

        default:
            header('Content-Type: application/json');
            http_response_code(404);
            echo json_encode(["success" => false, "message" => "Endpoint not found: " . $apiPath]);
            exit();
    }
} catch (Exception $e) {
    header('Content-Type: application/json');
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Server error: " . $e->getMessage()]);
    exit();
}
