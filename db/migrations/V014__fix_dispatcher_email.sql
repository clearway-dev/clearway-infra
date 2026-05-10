-- V014: Fix dispatcher seed email to match production value.
UPDATE users SET email = 'dispecink@clearway.cz' WHERE email = 'dispecink@hzs-pk.cz';
