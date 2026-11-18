<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        if ("POST".equals(request.getMethod())) {
            int group = Integer.parseInt(request.getParameter("groupId"));
            updateSQL(db, "INSERT INTO MEMBER_OF VALUES (?, ?, 'MEMBER')",
                    session.getAttribute("userId"),
                    group);
            session.setAttribute("groupId", group);
        }

        try (PreparedStatement s = prepare(db, """
                SELECT G.group_id, G.group_name, G.description FROM STUDY_GROUP G
                WHERE NOT EXISTS (SELECT 1 FROM MEMBER_OF M
                                  WHERE M.group_id = G.group_id AND M.user_id = ?)
                ORDER BY G.group_id
                """, session.getAttribute("userId"));
             ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head><title>05 그룹 가입</title></head>
<body>
<form method="post">
<table>
    <tr><th>가입할 그룹 ID</th><td><input name="groupId" type="number" required></td></tr>
</table>
<button type="submit">가입</button>
</form>
<table>
    <tr>
    <% for (int i = 1; i <= r.getMetaData().getColumnCount(); i++) { %>
        <th><%= escapeHtml(r.getMetaData().getColumnLabel(i)) %></th>
    <% } %>
    </tr>
    <% while (r.next()) { %>
    <tr>
        <% for (int i = 1; i <= r.getMetaData().getColumnCount(); i++) { %>
        <td><%= escapeHtml(r.getString(i)) %></td>
        <% } %>
    </tr>
    <% } %>
</table>
</body>
</html>
<%
        }
    } catch (Exception ignored) {
    }
%>
