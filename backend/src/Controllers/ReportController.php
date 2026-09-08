<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../Models/StudentExam.php';
require_once __DIR__ . '/../Middleware/AuthMiddleware.php';

class ReportController {
    private $db;
    private $studentExamModel;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->studentExamModel = new StudentExam($this->db);
    }

    public function downloadResultPDF() {
        // Anyone authenticated can query, but student can only check their own
        $decoded = AuthMiddleware::authenticate(['student', 'teacher', 'admin']);
        $student_exam_id = isset($_GET['student_exam_id']) ? intval($_GET['student_exam_id']) : null;

        if (!$student_exam_id) {
            $this->respondError("Student exam session ID required", 400);
        }

        $session = $this->studentExamModel->findById($student_exam_id);
        if (!$session) {
            $this->respondError("Session not found", 404);
        }

        if ($decoded['role'] === 'student' && $session['student_id'] != $decoded['id']) {
            $this->respondError("Access denied", 403);
        }

        $answers = $this->studentExamModel->getAnswersBySession($student_exam_id);

        // Generate a beautiful, print-ready, professional HTML certificate and scorecard
        // This is highly compatible with printing to PDF on all browsers/devices.
        $statusText = $session['score'] >= $session['passing_marks'] ? "PASSED" : "FAILED";
        $statusColor = $session['score'] >= $session['passing_marks'] ? "#22C55E" : "#EF4444";
        $percentage = round(($session['score'] / $session['total_marks']) * 100, 2);

        ?>
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>SmartExam - Scorecard</title>
            <style>
                body {
                    font-family: 'Inter', system-ui, -apple-system, sans-serif;
                    background: #F8FAFC;
                    color: #0F172A;
                    margin: 0;
                    padding: 40px;
                }
                .container {
                    max-width: 800px;
                    margin: 0 auto;
                    background: #FFFFFF;
                    padding: 40px;
                    border-radius: 12px;
                    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
                    border: 1px solid #E2E8F0;
                }
                .header {
                    text-align: center;
                    border-bottom: 2px solid #F1F5F9;
                    padding-bottom: 20px;
                    margin-bottom: 30px;
                }
                .logo {
                    font-size: 28px;
                    font-weight: 800;
                    color: #2563EB;
                    letter-spacing: -0.05em;
                }
                .tagline {
                    font-size: 12px;
                    color: #64748B;
                    text-transform: uppercase;
                    letter-spacing: 0.1em;
                }
                .title {
                    font-size: 22px;
                    font-weight: 700;
                    margin-top: 15px;
                    color: #0F172A;
                }
                .grid {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 20px;
                    margin-bottom: 35px;
                }
                .info-card {
                    background: #F8FAFC;
                    padding: 15px 20px;
                    border-radius: 8px;
                    border: 1px solid #E2E8F0;
                }
                .label {
                    font-size: 11px;
                    text-transform: uppercase;
                    color: #64748B;
                    font-weight: 600;
                }
                .val {
                    font-size: 16px;
                    font-weight: 700;
                    color: #0F172A;
                    margin-top: 5px;
                }
                .score-section {
                    text-align: center;
                    background: #F8FAFC;
                    border-radius: 12px;
                    padding: 30px;
                    margin-bottom: 40px;
                    border: 2px dashed #E2E8F0;
                }
                .score-badge {
                    display: inline-block;
                    font-size: 48px;
                    font-weight: 900;
                    color: #2563EB;
                }
                .status-badge {
                    display: inline-block;
                    margin-top: 10px;
                    padding: 6px 16px;
                    font-weight: 800;
                    font-size: 14px;
                    border-radius: 9999px;
                    color: white;
                    background: <?php echo $statusColor; ?>;
                }
                .table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 20px;
                }
                .table th {
                    text-align: left;
                    background: #0F172A;
                    color: white;
                    padding: 10px;
                    font-size: 12px;
                    text-transform: uppercase;
                }
                .table td {
                    padding: 12px 10px;
                    border-bottom: 1px solid #E2E8F0;
                    font-size: 14px;
                }
                .btn-print {
                    display: block;
                    width: 100%;
                    text-align: center;
                    background: #2563EB;
                    color: white;
                    padding: 12px 0;
                    border-radius: 8px;
                    font-weight: 700;
                    text-decoration: none;
                    margin-top: 30px;
                    cursor: pointer;
                    border: none;
                }
                @media print {
                    body {
                        background: white;
                        padding: 0;
                    }
                    .container {
                        box-shadow: none;
                        border: none;
                    }
                    .btn-print {
                        display: none;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="logo">SmartExam</div>
                    <div class="tagline">Smart Assessment, Better Learning</div>
                    <div class="title">Official Examination Scorecard</div>
                </div>

                <div class="grid">
                    <div class="info-card">
                        <div class="label">Student Name</div>
                        <div class="val"><?php echo htmlspecialchars($session['student_name']); ?></div>
                    </div>
                    <div class="info-card">
                        <div class="label">Exam Name</div>
                        <div class="val"><?php echo htmlspecialchars($session['exam_title']); ?></div>
                    </div>
                    <div class="info-card">
                        <div class="label">Start Time</div>
                        <div class="val"><?php echo htmlspecialchars($session['start_time']); ?></div>
                    </div>
                    <div class="info-card">
                        <div class="label">Submission Time</div>
                        <div class="val"><?php echo htmlspecialchars($session['submit_time']); ?></div>
                    </div>
                </div>

                <div class="score-section">
                    <div class="score-badge"><?php echo $session['score']; ?> / <?php echo $session['total_marks']; ?></div>
                    <div>Score Percentage: <strong><?php echo $percentage; ?>%</strong></div>
                    <div>Passing Marks Required: <strong><?php echo $session['passing_marks']; ?></strong></div>
                    <br>
                    <div class="status-badge"><?php echo $statusText; ?></div>
                </div>

                <h3>Question Breakdown</h3>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Question</th>
                            <th>Choice</th>
                            <th>Status</th>
                            <th>Marks</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($answers as $ans): ?>
                            <tr>
                                <td><?php echo htmlspecialchars($ans['question_text']); ?></td>
                                <td><?php echo htmlspecialchars($ans['selected_option_text'] ?? 'Unanswered'); ?></td>
                                <td>
                                    <strong style="color: <?php echo $ans['is_correct'] ? '#22C55E' : '#EF4444'; ?>">
                                        <?php echo $ans['is_correct'] ? 'Correct' : 'Incorrect/Unanswered'; ?>
                                    </strong>
                                </td>
                                <td><?php echo $ans['marks_obtained']; ?> / <?php echo $ans['q_marks']; ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>

                <button class="btn-print" onclick="window.print()">Print Scorecard / Save as PDF</button>
            </div>
        </body>
        </html>
        <?php
        exit();
    }

    public function exportResultsCSV() {
        AuthMiddleware::authenticate(['teacher', 'admin']);
        $exam_id = isset($_GET['exam_id']) ? intval($_GET['exam_id']) : null;

        if (!$exam_id) {
            $this->respondError("Exam ID required", 400);
        }

        $results = $this->studentExamModel->getResultsByExam($exam_id);

        header('Content-Type: text/csv');
        header('Content-Disposition: attachment; filename="exam_results_' . $exam_id . '.csv"');
        
        $output = fopen('php://output', 'w');
        
        // Output headers
        fputcsv($output, ['Session ID', 'Student Name', 'Student Email', 'Status', 'Start Time', 'Submit Time', 'Tab Switches', 'Fullscreen Exits', 'Score', 'Auto Submitted']);
        
        foreach ($results as $row) {
            fputcsv($output, [
                $row['id'],
                $row['student_name'],
                $row['student_email'],
                $row['status'],
                $row['start_time'],
                $row['submit_time'],
                $row['tab_switches_count'],
                $row['fullscreen_exits_count'],
                $row['score'],
                $row['auto_submitted'] ? 'Yes' : 'No'
            ]);
        }
        
        fclose($output);
        exit();
    }

    private function respondError($message, $code) {
        header('Content-Type: application/json');
        http_response_code($code);
        echo json_encode([
            "success" => false,
            "message" => $message
        ]);
        exit();
    }
}
