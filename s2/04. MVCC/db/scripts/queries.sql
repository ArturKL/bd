SELECT xmin, xmax, ctid, * FROM role;
UPDATE role SET is_system = true WHERE code = 'admin';
SELECT xmin, xmax, ctid, * FROM role;

CREATE EXTENSION IF NOT EXISTS pageinspect;
SELECT lp, t_xmin, t_xmax, t_ctid, t_infomask
FROM heap_page_items(get_raw_page('role', 0));