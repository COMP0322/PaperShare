<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        if ("POST".equals(request.getMethod())) {
            session.setAttribute("groupId", Integer.valueOf(request.getParameter("groupId")));
        }

        try (PreparedStatement s = prepare(db, """
                SELECT G.group_id, G.group_name, M.role
                FROM STUDY_GROUP G JOIN MEMBER_OF M ON G.group_id = M.group_id
                WHERE M.user_id = ? ORDER BY G.group_id
                """, session.getAttribute("userId"));
             ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head><title>03 현재 그룹 변경</title></head>
<body>
<form method="post">
<table>
    <tr>
        <th>내 그룹 ID</th>
        <td>
            <input name="groupId" type="number" required>
        </td>
    </tr>
</table>
<button type="submit">변경</button>
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
