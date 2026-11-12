<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ page import="java.net.InetAddress,java.util.ArrayList,java.util.List" %>
<%@ page import="java.sql.Connection,java.sql.DriverManager,java.sql.ResultSet,java.sql.SQLException,java.sql.Statement" %>

<%!
    private static final String DB_URL = "jdbc:oracle:thin:@//127.0.0.1:1522/FREEPDB1";
    private static final String DB_USER = "system";
    private static final String DB_PASSWORD = "oracle";

    private static String escapeHtml(String value) {
        return value == null ? "" : value.replace("&", "&amp;")
                .replace("<", "&lt;").replace(">", "&gt;");
    }
%>

<%
    response.setHeader("Cache-Control", "no-store");
    if (!InetAddress.getByName(request.getRemoteAddr()).isLoopbackAddress()) {
        response.sendError(403);
        return;
    }

    List<String[]> papers = new ArrayList<>();
    boolean queryFailed = false;
    try {
        Class.forName("oracle.jdbc.driver.OracleDriver");
        String sql = "SELECT paper_id, title, authors, year FROM PAPER ORDER BY paper_id";
        try (Connection connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
             Statement statement = connection.createStatement();
             ResultSet rows = statement.executeQuery(sql)) {
            while (rows.next()) {
                papers.add(new String[] {
                        rows.getString(1), rows.getString(2), rows.getString(3), rows.getString(4)
                });
            }
        }
    } catch (ClassNotFoundException | SQLException exception) {
        queryFailed = true;
        response.setStatus(503);
        application.log("Unable to read the PAPER table", exception);
    }
%>

<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>PaperShare 논문 목록</title>
    <style>
        body { margin: 0; color: #182230; font: 1rem/1.5 system-ui, sans-serif; }
        main { max-width: 68rem; margin: 2rem auto; padding: 0 1rem; }
        .table-scroll { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; text-align: left; }
        caption { text-align: left; margin-bottom: .75rem; color: #475467; }
        th, td { padding: .65rem .75rem; border-bottom: 1px solid #d9e0e7; vertical-align: top; }
        thead th { background: #edf2f7; white-space: nowrap; }
        tbody th { font-weight: normal; }
        tbody tr:nth-child(even) { background: #f8fafc; }
    </style>
</head>
<body>
<main>
    <h1>PaperShare 논문 목록</h1>
    <% if (queryFailed) { %>
        <p>논문을 불러오지 못했습니다. IntelliJ의 Tomcat 실행 로그에서 원인을 확인하세요.</p>
    <% } else { %>
        <div class="table-scroll">
            <table>
                <caption>PAPER · <%= papers.size() %>편</caption>
                <thead>
                    <tr>
                        <th scope="col">논문 ID</th>
                        <th scope="col">제목</th>
                        <th scope="col">저자</th>
                        <th scope="col">발행 연도</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (papers.isEmpty()) { %>
                        <tr><td colspan="4">등록된 논문이 없습니다.</td></tr>
                    <% } else {
                        for (String[] paper : papers) { %>
                            <tr>
                                <th scope="row"><%= escapeHtml(paper[0]) %></th>
                                <td><%= escapeHtml(paper[1]) %></td>
                                <td><%= escapeHtml(paper[2]) %></td>
                                <td><%= escapeHtml(paper[3]) %></td>
                            </tr>
                        <% }
                    } %>
                </tbody>
            </table>
        </div>
    <% } %>
</main>
</body>
</html>
