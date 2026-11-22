-- Type 1: 단일 테이블 Selection + Projection.
-- IN (?)는 Java에서 현재 그룹의 논문 개수만큼 바인드 변수로 확장한다. 저자 입력 시 AND 조건 추가.
SELECT paper_id, title, authors, year FROM PAPER
WHERE year >= ? AND LOWER(title) LIKE LOWER(?) AND paper_id IN (?);

-- Type 2: WHERE 다중 조인. 현재 그룹 ID와 그룹명 일부를 바인딩한다.
SELECT G.group_id, G.group_name, U.user_id, U.name, U.affiliation
FROM STUDY_GROUP G, MEMBER_OF M, USERS U
WHERE G.group_id = M.group_id AND M.user_id = U.user_id
AND G.group_id = ? AND M.role = 'LEADER' AND LOWER(G.group_name) LIKE LOWER(?);

-- Type 3: 집계 + 다중 조인 + GROUP BY. 현재 그룹의 최소 완료 편수.
SELECT G.group_id, G.group_name, COUNT(P.paper_id) AS done_count, MAX(P.year) AS latest_year
FROM STUDY_GROUP G, GROUP_PAPER GP, PAPER P
WHERE G.group_id = GP.group_id AND GP.paper_id = P.paper_id
AND G.group_id = ? AND GP.status = '완료'
GROUP BY G.group_id, G.group_name HAVING COUNT(P.paper_id) >= ?;

-- Type 4: 스칼라 서브쿼리. 현재 그룹 논문의 평균 연도를 기준으로 비교한다.
SELECT P.paper_id, P.title, P.year FROM PAPER P
WHERE P.paper_id IN (SELECT GP.paper_id FROM GROUP_PAPER GP WHERE GP.group_id = ?)
AND P.year > (SELECT AVG(P2.year) FROM PAPER P2, GROUP_PAPER GP2
              WHERE P2.paper_id = GP2.paper_id AND GP2.group_id = ?) + ?;

-- Type 5: EXISTS. 현재 그룹에서 답글을 받은 댓글.
SELECT C.group_paper_id, C.comment_no, P.title, U.name, C.content
FROM PAPER_COMMENT C, GROUP_PAPER GP, PAPER P, USERS U
WHERE C.group_paper_id = GP.group_paper_id AND GP.paper_id = P.paper_id
AND C.user_id = U.user_id AND GP.group_id = ?
AND EXISTS (SELECT 1 FROM PAPER_COMMENT R
WHERE R.group_paper_id = C.group_paper_id AND R.parent_comment_no = C.comment_no);

-- Type 6: IN. 현재 그룹 논문 중 입력한 두 태그 중 하나가 붙은 논문.
SELECT P.paper_id, P.title, P.year FROM PAPER P
WHERE P.paper_id IN (SELECT GP.paper_id FROM GROUP_PAPER GP WHERE GP.group_id = ?)
AND P.paper_id IN (SELECT PT.paper_id FROM PAPER_TAG PT, TAG T
WHERE PT.tag_id = T.tag_id AND T.tag_name IN (?, ?));

-- Type 7: 인라인 뷰. 현재 그룹의 등록 논문 수와 입력한 최소 편수 비교.
SELECT G.group_id, G.group_name, V.paper_count
FROM STUDY_GROUP G, (SELECT group_id, COUNT(*) AS paper_count FROM GROUP_PAPER GROUP BY group_id) V
WHERE G.group_id = V.group_id AND G.group_id = ? AND V.paper_count >= ?;

-- Type 8: WHERE 다중 조인 + ORDER BY. 현재 그룹의 하이라이트.
SELECT G.group_name, GP.group_paper_id, P.title, H.highlight_no, U.name AS author_name,
H.page_no, H.start_position, H.end_position, H.selected_text, H.created_at
FROM STUDY_GROUP G, GROUP_PAPER GP, PAPER P, HIGHLIGHT H, USERS U
WHERE G.group_id = GP.group_id AND GP.paper_id = P.paper_id
AND GP.group_paper_id = H.group_paper_id AND H.user_id = U.user_id AND G.group_id = ?
ORDER BY P.title, H.page_no, H.start_position, GP.group_paper_id, H.highlight_no;

-- Type 9: 집계 + 다중 조인 + GROUP BY + ORDER BY. 현재 그룹의 댓글 통계.
SELECT G.group_id, G.group_name, GP.group_paper_id, P.paper_id, P.title,
COUNT(C.comment_no) AS comment_count, COUNT(DISTINCT C.user_id) AS commenter_count
FROM STUDY_GROUP G, GROUP_PAPER GP, PAPER P, PAPER_COMMENT C
WHERE G.group_id = GP.group_id AND GP.paper_id = P.paper_id
AND GP.group_paper_id = C.group_paper_id AND G.group_id = ?
GROUP BY G.group_id, G.group_name, GP.group_paper_id, P.paper_id, P.title
HAVING COUNT(C.comment_no) >= ? ORDER BY comment_count DESC, GP.group_paper_id;

-- Type 10: INTERSECT. 현재 그룹에서 하이라이트와 댓글을 모두 작성한 사용자.
SELECT U.user_id, U.name FROM USERS U, HIGHLIGHT H, GROUP_PAPER GP
WHERE U.user_id = H.user_id AND H.group_paper_id = GP.group_paper_id
AND GP.group_id = ? AND U.name LIKE ?
INTERSECT
SELECT U.user_id, U.name FROM USERS U, PAPER_COMMENT C, GROUP_PAPER GP
WHERE U.user_id = C.user_id AND C.group_paper_id = GP.group_paper_id AND GP.group_id = ?;
