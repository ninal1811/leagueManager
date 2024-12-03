<?php include __DIR__ . '/header.php'; ?>
<head>
    <meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" type="text/css" href="style.css">
	<title></title>
</head>
<body class="bg">
    <div class="container">
        <div>
            <div class="dashboard">
                <h1>Welcome, <?php echo htmlspecialchars($_SESSION['fullname']); ?>!</h1>
                <a href="/leagueManager/logout.php">Logout</a>
            </div>
            <div class="dashboard">
                <a href="/leagueManager/team.php" class="menu">Team</a>
                <a href="/leagueManager/league.php" class="menu">League</a>
                <a href="/leagueManager/player.php" class="menu">Players</a>
                <a href="/leagueManager/match.php" class="menu">Match</a>
            </div>
        </div>
    </div>
</body>
<?php include __DIR__ . '/footer.php'; ?>