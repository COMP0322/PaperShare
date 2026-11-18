<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        if ("POST".equals(request.getMethod())) {
            int user = Integer.parseInt(request.getParameter("userId"));
            try (PreparedStatement s = prepare(db, "SELECT group_id FROM MEMBER_OF WHERE user_id = ? ORDER BY group_id", user);
                 ResultSet r = s.executeQuery()) {
                session.setAttribute("groupId", r.next() ? r.getInt(1) : null);
            }
            session.setAttribute("userId", user);
        }

        try (PreparedStatement s = prepare(db, "SELECT user_id, name, affiliation FROM USERS ORDER BY user_id");
             ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head><title>01 사용자 전환</title></head>
<body>
<form method="post">
<table>
    <tr>
        <th>사용자 ID</th>
        <td>
            <input name="userId" type="number" required>
        </td>
    </tr>
</table>
<button type="submit">전환</button>
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
