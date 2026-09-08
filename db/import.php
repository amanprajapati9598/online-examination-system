<?php
$host = '127.0.0.1';
$user = 'root';
$pass = 'root';
$sqlFile = __DIR__ . '/schema.sql';

try {
    // Connect to MySQL
    $pdo = new PDO("mysql:host=$host;charset=utf8", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);
    
    echo "Connected to MySQL successfully.\n";
    
    // Read and parse SQL file
    $sql = file_get_contents($sqlFile);
    if ($sql === false) {
        throw new Exception("Could not read SQL file.");
    }
    
    // Execute SQL content
    $pdo->exec($sql);
    echo "Database schema imported successfully into 'smartexam_db'!\n";
    
} catch (Exception $e) {
    echo "Error during database import: " . $e->getMessage() . "\n";
    exit(1);
}
