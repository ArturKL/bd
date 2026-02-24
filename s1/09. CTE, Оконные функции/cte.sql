SELECT
    flow_id,
    user_id,
    enrolled_at,
    LAST_VALUE(user_id) OVER (
        PARTITION BY flow_id ORDER BY enrolled_at
        RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_student
FROM enrollment
WHERE enrolled_at IS NOT NULL
ORDER BY flow_id, enrolled_at;
