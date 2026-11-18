<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb();
         PreparedStatement s = prepare(db, """
                SELECT P.title, P.authors, P.year, P.DOI, GP.status, GP.notes,
                       GP.added_date, GP.started_date, GP.completed_date
                FROM GROUP_PAPER GP JOIN PAPER P ON P.paper_id = GP.paper_id
                WHERE GP.group_id = ? ORDER BY GP.group_paper_id
                """, currentGroup(db, session));

         ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head><title>07 그룹 논문·메모 조회</title></head>
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
