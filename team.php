<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

include __DIR__ . '/includes/db_connection.php';
include __DIR__ . '/includes/session_check.php';

$error = '';
$success = '';

// Determine sorting order and column
$sort_column = isset($_GET['sort_by']) && in_array($_GET['sort_by'], ['TotalPoints', 'Team_ID']) ? $_GET['sort_by'] : 'TotalPoints';
$sort_order = isset($_GET['sort_order']) && $_GET['sort_order'] === 'asc' ? 'ASC' : 'DESC';

// Fetch teams for the current user
$user_id = $_SESSION['user_id'];
try {
    $stmt = $pdo->prepare("SELECT * FROM Team WHERE Owner = ? ORDER BY $sort_column $sort_order");
    $stmt->execute([$user_id]);
    $teams = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $error = "Error fetching teams: " . $e->getMessage();
}

// Fetch waivers for the user's teams
try {
    $stmt = $pdo->prepare("
        SELECT W.Waiver_ID, W.Team_ID, W.Player_ID, W.WaiverOrder, W.WaiverStatus, W.WaiverPickupDate
        FROM Waiver W
        JOIN Team T ON W.Team_ID = T.Team_ID
        WHERE T.Owner = ?
    ");
    $stmt->execute([$user_id]);
    $waivers = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $error = "Error fetching waivers: " . $e->getMessage();
}

// Fetch trades for the user's teams
try {
    $stmt = $pdo->prepare("
        SELECT Tr.Trade_ID, Tr.Team1_ID, Tr.Team2_ID, Tr.TradedPlayer1_ID, Tr.TradedPlayer2_ID, Tr.TradeDate
        FROM Trade Tr
        JOIN Team T1 ON Tr.Team1_ID = T1.Team_ID
        JOIN Team T2 ON Tr.Team2_ID = T2.Team_ID
        WHERE T1.Owner = ? OR T2.Owner = ?
    ");
    $stmt->execute([$user_id, $user_id]);
    $trades = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $error = "Error fetching trades: " . $e->getMessage();
}

// Handle form submission to add a new team
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $team_name = $_POST['team_name'] ?? '';
    $league_id = $_POST['league_id'] ?? '';

    if (!empty($team_name) && !empty($league_id)) {
        try {
            // Call the stored procedure to add the team
            $stmt = $pdo->prepare("CALL AddTeam(?, ?, ?)");
            $stmt->execute([$team_name, $user_id, $league_id]);
            $success = "Team added successfully!";

            // Refresh the team list after adding
            $stmt = $pdo->prepare("SELECT * FROM Team WHERE Owner = ? ORDER BY $sort_column $sort_order");
            $stmt->execute([$user_id]);
            $teams = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Refresh waivers and trades
            $stmt = $pdo->prepare("
                SELECT W.Waiver_ID, W.Team_ID, W.Player_ID, W.WaiverOrder, W.WaiverStatus, W.WaiverPickupDate
                FROM Waiver W
                JOIN Team T ON W.Team_ID = T.Team_ID
                WHERE T.Owner = ?
            ");
            $stmt->execute([$user_id]);
            $waivers = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $stmt = $pdo->prepare("
                SELECT Tr.Trade_ID, Tr.Team1_ID, Tr.Team2_ID, Tr.TradedPlayer1_ID, Tr.TradedPlayer2_ID, Tr.TradeDate
                FROM Trade Tr
                JOIN Team T1 ON Tr.Team1_ID = T1.Team_ID
                JOIN Team T2 ON Tr.Team2_ID = T2.Team_ID
                WHERE T1.Owner = ? OR T2.Owner = ?
            ");
            $stmt->execute([$user_id, $user_id]);
            $trades = $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            if ($e->getCode() == 23000) {
                $error = "The specified League ID does not exist.";
            } else {
                $error = "Error adding team: " . $e->getMessage();
            }
        }
    } else {
        $error = "Team name and league are required.";
    }
}

include __DIR__ . '/templates/team.html.php';
