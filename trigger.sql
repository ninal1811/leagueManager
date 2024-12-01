DELIMITER $$

CREATE PROCEDURE AddUser(
    IN p_UserName VARCHAR(20),
    IN p_Email VARCHAR(50),
    IN p_Password VARCHAR(64),
    IN p_FullName VARCHAR(64)
)
BEGIN

    -- Check if the email already exists
    -- IF EXISTS (SELECT 1 FROM User WHERE Email = p_Email) THEN
        -- SIGNAL SQLSTATE '45000' 
        -- SET MESSAGE_TEXT = 'Email already exists. Please use a different email.';
    -- ELSE
        -- Insert the new user
        DECLARE next_ID NUMERIC(8,0);
        SELECT IFNULL(MAX(User_ID), 0) + 1 INTO next_ID FROM User;

        INSERT INTO User (User_ID, UserName, Email, Password, FullName, ProfileSettings)
        VALUES (next_ID, p_UserName, p_Email, p_Password, p_FullName, '{"theme":"light","notifications":false}');
    -- END IF;
END $$

DELIMITER ;


CALL AddUser('usertest','user@gmail.com','123456','User Test');


-- add match 


DELIMITER @@

CREATE TRIGGER BeforeMatchInsert
BEFORE INSERT ON `Match`
FOR EACH ROW
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE randomScore INT;
    DECLARE randomAssists INT;
    DECLARE next_ID NUMERIC(10,0);
    SELECT IFNULL(MAX(Statistic_ID), 0) INTO next_ID FROM Player_Statistic;

    -- Loop to insert 10 random rows into PlayerStatistics for the new match
    WHILE i <= 10 DO
        -- Generate random data for PlayerID, Score, and Assists
        SET randomScore = FLOOR(RAND() * 8);           -- Random Score between 0 and 30
        SET randomAssists = FLOOR(RAND() * 3);         -- Random Assists between 0 and 10
        SET next_ID = next_ID + 1;

        -- Insert a row into PlayerStatistics
        INSERT INTO PlayerStatistics (MatchID, PlayerID, Score, Assists)
        VALUES (next_ID, , randomScore, randomAssists);

        -- Increment the loop counter
        SET i = i + 1;
    END WHILE;
END @@

DELIMITER ;


-- retrivier all player from the given team ID
DELIMITER $$
CREATE PROCEDURE GetPlayersByTeam(IN p_Team_ID INT)
BEGIN
SELECT Player.FullName, Player.Position, Player.FantasyPoints
FROM Player INNER JOIN Team 
ON Player.Team_ID = Team.Team_ID
WHERE  Team.Team_ID = p_Team_ID;
END $$
DELIMITER;


-- add a team give League ID and userID
DELIMITER $$

CREATE PROCEDURE AddTeam (
    IN p_TeamName VARCHAR(25),
    IN p_User_ID NUMERIC(8,0),
    IN p_League_ID VARCHAR(50)
)
BEGIN
    DECLARE next_ID NUMERIC(8,0);
    SELECT IFNULL(MAX(Team_ID), 0) + 1 INTO next_ID FROM Team;
    INSERT INTO Team (Team_ID,TeamName, Owner, League_ID, Status)
    -- team default status available with ranking NUll
    VALUES (next_ID,p_TeamName,p_User_ID, p_League_ID,'A');
END $$

DELIMITER ;

CALL AddTeam('teamtest',1,1);


-- trigger after insert on trade table 
DELIMITER $$

CREATE TRIGGER AfterTradeInsert
AFTER INSERT ON Trade
FOR EACH ROW
BEGIN
    DECLARE team1ID NUMERIC(8,0);
    DECLARE team2ID NUMERIC(8,0);
    DECLARE player1ID NUMERIC(8,0);
    DECLARE player2ID NUMERIC(8,0);
    
    -- Retrieve the data from the new column of trade
    SET team1ID = NEW.Team1_ID;
    SET team2ID = NEW.Team2_ID;
    SET player1ID = NEW.TradedPlayer1_ID;
    SET player2ID = NEW.TradedPlayer2_ID;

    -- Insert 2 row into Player_Trade
    INSERT INTO Player_Trade (Player_ID, Trade_ID)
    VALUES (player1ID, New.Trade_ID);

    INSERT INTO Player_Trade (Player_ID, Trade_ID)
    VALUES (player2ID, New.Trade_ID);


    -- Insert 2 row into Team_Trade
    INSERT INTO Team_Trade (Trade_ID, Team_ID)
    VALUES (New.Trade_ID, team1ID);

    INSERT INTO Team_Trade (Trade_ID, Team_ID)
    VALUES (New.Trade_ID, team2ID);

    -- Update the player's Team_ID to reflect the new team
    -- player 1 is traded to team 2
    -- player 2 is traded to team 1
    UPDATE Player
    SET Team_ID = team2ID
    WHERE Player_ID = player1ID;

    UPDATE Player
    SET Team_ID = team1ID
    WHERE Player_ID = player2ID ;

END $$

DELIMITER ;



-- data retrival for all match based on a user
DELIMITER $$
CREATE PROCEDURE GetMatchByUser(IN p_User_ID INT)
    BEGIN
    SELECT m.* 
    FROM MatchInfo m INNER JOIN Team t
    ON m.Team1_ID = t.Team_ID OR m.Team2_ID = t.Team_ID
    INNER JOIN User u 
    ON t.Owner = u.User_ID
    WHERE u.User_ID = p_User_ID;
END $$
DELIMITER ;



-- data retrival for all players in a user's teams
DELIMITER $$
CREATE PROCEDURE GetPlayerFromUser(IN p_User_ID INT)
    BEGIN
    SELECT p.* 
    FROM Player p INNER JOIN Team t
    ON p.Team_ID = t.Team_ID
    WHERE t.owner = p_User_ID;
END $$
DELIMITER;

CALL GetPlayerFromUser(1);

-- data retrival for all teams that a user owns
DELIMITER $$
CREATE PROCEDURE GetTeamFromUser(IN p_User_ID INT)
BEGIN
SELECT *
FROM Team  
WHERE owner = p_User_ID;
END $$
DELIMITER ;

CALL GetTeamFromUser(1);


-- data retrival for leauges owned by a given user
DELIMITER $$
CREATE PROCEDURE GetLeagueFromUser(IN p_User_ID INT)
BEGIN
    SELECT *
    FROM League
    WHERE User_ID = p_User_ID;
END $$

DELIMITER ;

CALL GetLeagueFromUser(1);

-- data retrival for teams in the league
DELIMITER $$
CREATE PROCEDURE GetTeamFromLeague(IN p_League_ID INT)
    BEGIN
    SELECT t.* 
    FROM Team t INNER JOIN League l
    ON t.League_ID = p_League_ID;
END $$
DELIMITER;

CALL GetTeamFromLeague(1);


-- add trade

CREATE PROCEDURE AddTrade (
    IN p_Team1_ID NUMERIC(8,0),
    IN p_Team2_ID NUMERIC(8,0),
    IN p_TraderPlayer1_ID NUMERIC(8,0)
    IN p_TraderPlayer2_ID NUMERIC(8,0)
)

BEGIN
    DECLARE next_ID NUMERIC(10,0);
    SELECT IFNULL(MAX(Trade_ID), 0) + 1 INTO next_ID FROM Trade;

    INSERT INTO Trade (Trade_ID,Team1_ID,Team2_ID,TradedPlayer1_ID,TradedPlayer2_ID,TradeDate)
    VALUES (next_ID,p_Team1_ID,p_Team2_ID,p_TraderPlayer1_ID,p_TraderPlayer2_ID,CURDATE());
END $$

DELIMITER ;

CALL AddTrade(1,2,1,6);



-- data retrival for playerStatistics from the current user
DELIMITER $$
CREATE PROCEDURE GetStatsFromUser(IN p_User_ID INT)
BEGIN
    SELECT ps.*
    FROM Player_Statistic ps INNER JOIN player p
    ON ps.Player_ID = p.Player_ID
    INNER JOIN team t
    ON p.Team_ID = t.Team_ID
    WHERE t.owner = p_User_ID;
END $$
DELIMITER ;

CALL GetStatsFromUser(1);
