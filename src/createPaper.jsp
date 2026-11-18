<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%!
    private int querySQL(Connection db, String sql) throws SQLException {
        try (PreparedStatement s = prepare(db, sql); ResultSet r = s.executeQuery()) {
            r.next();
            return r.getInt(1);
        }
    }
%>
<%
    if ("POST".equals(request.getMethod())) {
        try (Connection db = openDb()) {
            db.setAutoCommit(false);
            try {
                int paper = querySQL(db, "SELECT NVL(MAX(paper_id), 0) + 1 FROM PAPER");
                updateSQL(db, "INSERT INTO PAPER VALUES (?, ?, ?, ?, ?, ?, ?)", paper,
                        request.getParameter("title"), request.getParameter("authors"),
                        request.getParameter("year"), request.getParameter("doi"),
                        request.getParameter("url"), request.getParameter("abstract"));

                updateSQL(db, """
                        INSERT INTO GROUP_PAPER
                        (group_paper_id, group_id, paper_id, status, added_date, notes)
                        VALUES (?, ?, ?, '읽음', SYSDATE, ?)
                        """, querySQL(db, "SELECT NVL(MAX(group_paper_id), 0) + 1 FROM GROUP_PAPER"),
                        currentGroup(db, session), paper, request.getParameter("notes"));

                db.commit();
            } finally {
                db.rollback();
            }
        } catch (Exception ignored) {
        }
    }
%>
<!doctype html>
<html lang="ko">
<head><title>08 논문 생성</title></head>
<body>
<form method="post">
<table>
    <tr>
        <th>제목</th>
        <td>
            <input name="title" required>
        </td>
    </tr>
    <tr>
        <th>저자</th>
        <td>
            <input name="authors" required>
        </td>
    </tr>
    <tr>
        <th>발행연도</th>
        <td>
            <input name="year" type="number" required min="1" max="9999"></td>
    </tr>
    <tr>
        <th>DOI</th>
        <td>
            <input name="doi" required>
        </td>
    </tr>
    <tr>
        <th>URL</th>
        <td>
            <input name="url" required>
        </td>
    </tr>
    <tr>
        <th>초록</th>
        <td>
            <textarea name="abstract" required></textarea>
        </td>
    </tr>
    <tr>
        <th>그룹 메모</th>
        <td>
            <textarea name="notes" required></textarea>
        </td>
    </tr>
</table>
<button type="submit">논문 생성 및 현재 그룹 등록</button>
</form>
</body>
</html>
