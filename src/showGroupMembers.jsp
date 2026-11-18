<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb();
         PreparedStatement s = prepare(db, """
                SELECT U.name, U.affiliation, M.role FROM USERS U
                JOIN MEMBER_OF M ON U.user_id = M.user_id
                WHERE M.group_id = ? ORDER BY U.user_id
                """, currentGroup(db, session));

         ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head><title>06 현재 그룹원 조회</title></head>
<body>
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
    } catch (Exception ignored) {
    }
%>
