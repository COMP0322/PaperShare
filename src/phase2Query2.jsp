<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        ResultSet r = null;
        if ("POST".equals(request.getMethod())) {
            r = prepare(db, """
                    SELECT G.group_id, G.group_name, U.user_id, U.name, U.affiliation
                    FROM STUDY_GROUP G, MEMBER_OF M, USERS U
                    WHERE G.group_id = M.group_id AND M.user_id = U.user_id
                    AND G.group_id = ? AND M.role = 'LEADER' AND LOWER(G.group_name) LIKE LOWER(?)
                    """, currentGroup(db, session), "%" + request.getParameter("groupName") + "%").executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head><title>17-2 그룹 리더</title></head>
<body>
<form method="post">
<table>
    <tr><th>그룹명 일부 (전체는 빈칸)</th><td><input name="groupName"></td></tr>
</table>
<button type="submit">조회</button>
</form>
<% if ("POST".equals(request.getMethod())) {
       int columns = r.getMetaData().getColumnCount();
%>
<table>
    <tr>
    <% for (int i = 1; i <= columns; i++) { %>
        <th><%= escapeHtml(r.getMetaData().getColumnLabel(i)) %></th>
    <% } %>
    </tr>
    <% while (r.next()) { %>
    <tr>
        <% for (int i = 1; i <= columns; i++) { %>
        <td><%= escapeHtml(r.getString(i)) %></td>
        <% } %>
    </tr>
    <% } %>
</table>
<% } %>
</body>
</html>
<%
    } catch (Exception ignored) {
    }
%>
