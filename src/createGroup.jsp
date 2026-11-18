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
                int group = querySQL(db, "SELECT NVL(MAX(group_id), 0) + 1 FROM STUDY_GROUP");
                updateSQL(db, "INSERT INTO STUDY_GROUP VALUES (?, ?, SYSTIMESTAMP, ?)",
                        group,
                        request.getParameter("groupName"),
                        request.getParameter("description"));

                updateSQL(db, "INSERT INTO MEMBER_OF VALUES (?, ?, 'LEADER')",
                        session.getAttribute("userId"),
                        group);

                db.commit();
                session.setAttribute("groupId", group);
            } finally {
                db.rollback();
            }
        } catch (Exception ignored) {
        }
    }
%>
<!doctype html>
<html lang="ko">
<head><title>04 그룹 생성</title></head>
<body>
<form method="post">
<table>
    <tr>
        <th>그룹명</th>
        <td>
            <input name="groupName" required>
        </td>
    </tr>
    <tr>
        <th>설명</th>
        <td>
            <textarea name="description" required></textarea>
        </td>
    </tr>
</table>
<button type="submit">생성</button>
</form>
</body>
</html>
