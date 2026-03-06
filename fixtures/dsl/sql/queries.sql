-- Complex query examples

-- Get users with their roles
SELECT
    u.id,
    u.username,
    u.email,
    COALESCE(STRING_AGG(r.name, ', '), 'No roles') AS roles
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.id
WHERE u.is_active = TRUE
GROUP BY u.id, u.username, u.email
ORDER BY u.created_at DESC
LIMIT 100 OFFSET 0;

-- Window function example
WITH monthly_stats AS (
    SELECT
        DATE_TRUNC('month', created_at) AS month,
        COUNT(*) AS new_users,
        ROW_NUMBER() OVER (ORDER BY DATE_TRUNC('month', created_at)) AS month_num
    FROM users
    GROUP BY DATE_TRUNC('month', created_at)
)
SELECT
    month,
    new_users,
    SUM(new_users) OVER (ORDER BY month_num) AS cumulative_users,
    LAG(new_users, 1) OVER (ORDER BY month_num) AS prev_month_users,
    CASE
        WHEN LAG(new_users, 1) OVER (ORDER BY month_num) IS NULL THEN NULL
        ELSE ROUND((new_users - LAG(new_users, 1) OVER (ORDER BY month_num))::DECIMAL /
             LAG(new_users, 1) OVER (ORDER BY month_num) * 100, 2)
    END AS growth_percent
FROM monthly_stats;

-- Subquery and EXISTS example
SELECT u.*
FROM users u
WHERE EXISTS (
    SELECT 1
    FROM user_roles ur
    INNER JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = u.id
      AND r.name IN ('admin', 'moderator')
);

-- Update with JOIN
UPDATE users u
SET updated_at = CURRENT_TIMESTAMP
FROM user_roles ur
WHERE u.id = ur.user_id
  AND u.is_active = TRUE;

-- Delete with subquery
DELETE FROM user_roles
WHERE user_id IN (
    SELECT id FROM users WHERE is_active = FALSE
);
