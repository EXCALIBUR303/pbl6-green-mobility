<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.StudentDAO" %>
<%@ page import="com.woxsen.greenmobility.model.Student" %>
<%@ page import="java.util.List" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    String pageTitle = "Leaderboard";
    StudentDAO studentDAO = new StudentDAO();
    List<Student> topStudents = studentDAO.getLeaderboard(10);
    request.setAttribute("topStudents", topStudents);

    List<Student> topByPoints = studentDAO.getPointsLeaderboard(10);
    request.setAttribute("topByPoints", topByPoints);

    // Where the current student sits, so we can call it out above the table.
    int myRank = 0;
    for (int i = 0; i < topStudents.size(); i++) {
        if (topStudents.get(i).getStudentId() == loggedInStudent.getStudentId()) {
            myRank = i + 1;
            break;
        }
    }
    request.setAttribute("myRank", myRank);
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
    <div>
        <h1 class="page-title text-forest mb-1">Carbon savings leaderboard</h1>
        <p class="text-secondary mb-0">Top green-mobility riders on campus.</p>
    </div>
    <c:if test="${myRank > 0}">
        <span class="pill pill-eco px-3 py-2">
            <i class="bi bi-person-badge"></i>You're ranked #${myRank}
        </span>
    </c:if>
</div>

<!-- Podium for the top three -->
<c:if test="${fn:length(topStudents) >= 3}">
    <div class="podium mb-4">
        <c:forEach var="s" items="${topStudents}" varStatus="st">
            <c:if test="${st.index < 3}">
                <%-- Visual order: 2nd, 1st, 3rd. --%>
                <c:set var="order" value="${st.index == 0 ? 2 : (st.index == 1 ? 1 : 3)}"/>
                <div class="podium-card p${st.index + 1}" style="order: ${order};">
                    <div class="podium-medal medal-${st.index + 1}">
                        <i class="bi bi-trophy-fill"></i>
                    </div>
                    <div class="avatar-circle avatar-muted mx-auto mb-2">
                        ${fn:substring(s.name, 0, 1)}
                    </div>
                    <div class="fw-bold text-truncate">${s.name}</div>
                    <c:if test="${s.studentId eq student.studentId}">
                        <span class="pill pill-eco mt-1">You</span>
                    </c:if>
                    <div class="stat-value mt-2" style="font-size:1.3rem;"
                         data-count="${s.totalCo2SavedKg}" data-decimals="2" data-suffix=" kg">0</div>
                </div>
            </c:if>
        </c:forEach>
    </div>
</c:if>

<div class="card p-4">
    <span class="section-label d-block mb-3">
        <i class="bi bi-list-ol me-1"></i>Full ranking
    </span>

    <div class="table-responsive">
        <table class="table align-middle mb-0">
            <thead>
            <tr>
                <th class="section-label" style="width:70px;">Rank</th>
                <th class="section-label">Student</th>
                <th class="section-label" style="min-width:200px;">Total CO<sub>2</sub> saved</th>
            </tr>
            </thead>
            <tbody data-reveal>
            <c:forEach var="s" items="${topStudents}" varStatus="rank">
                <tr class="${s.studentId eq student.studentId ? 'row-me' : ''}">
                    <td>
                        <c:choose>
                            <c:when test="${rank.index < 3}">
                                <span class="podium-medal medal-${rank.index + 1}"
                                      style="width:30px;height:30px;font-size:.8rem;margin:0;">
                                    <i class="bi bi-trophy-fill"></i>
                                </span>
                            </c:when>
                            <c:otherwise>
                                <span class="rank-num">${rank.index + 1}</span>
                            </c:otherwise>
                        </c:choose>
                    </td>
                    <td>
                        <div class="d-flex align-items-center gap-3">
                            <span class="avatar-circle avatar-muted">${fn:substring(s.name, 0, 1)}</span>
                            <div>
                                <span class="fw-semibold">${s.name}</span>
                                <c:if test="${s.studentId eq student.studentId}">
                                    <span class="pill pill-eco ms-1">You</span>
                                </c:if>
                            </div>
                        </div>
                    </td>
                    <td>
                        <div class="d-flex align-items-center gap-3">
                            <div class="bar-track flex-grow-1" style="max-width:150px;">
                                <div class="bar-fill ${s.studentId eq student.studentId ? 'is-me' : ''}"
                                     data-fill="${topStudents[0].totalCo2SavedKg > 0
                                         ? (s.totalCo2SavedKg / topStudents[0].totalCo2SavedKg) * 100 : 0}"></div>
                            </div>
                            <span class="fw-bold text-nowrap" style="font-variant-numeric: tabular-nums;">
                                ${s.totalCo2SavedKg} kg
                            </span>
                        </div>
                    </td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
</div>

<div class="card p-4 mt-4">
    <span class="section-label d-block mb-3">
        <i class="bi bi-star-fill me-1"></i>Points leaderboard
    </span>

    <div class="table-responsive">
        <table class="table align-middle mb-0">
            <thead>
            <tr>
                <th class="section-label" style="width:70px;">Rank</th>
                <th class="section-label">Student</th>
                <th class="section-label" style="min-width:200px;">Points</th>
            </tr>
            </thead>
            <tbody>
            <c:forEach var="s" items="${topByPoints}" varStatus="rank">
                <tr class="${s.studentId eq student.studentId ? 'row-me' : ''}">
                    <td>
                        <c:choose>
                            <c:when test="${rank.index < 3}">
                                <span class="podium-medal medal-${rank.index + 1}"
                                      style="width:30px;height:30px;font-size:.8rem;margin:0;">
                                    <i class="bi bi-trophy-fill"></i>
                                </span>
                            </c:when>
                            <c:otherwise>
                                <span class="rank-num">${rank.index + 1}</span>
                            </c:otherwise>
                        </c:choose>
                    </td>
                    <td>
                        <div class="d-flex align-items-center gap-3">
                            <span class="avatar-circle avatar-muted">${fn:substring(s.name, 0, 1)}</span>
                            <div>
                                <span class="fw-semibold">${s.name}</span>
                                <c:if test="${s.studentId eq student.studentId}">
                                    <span class="pill pill-eco ms-1">You</span>
                                </c:if>
                            </div>
                        </div>
                    </td>
                    <td>
                        <div class="d-flex align-items-center gap-3">
                            <div class="bar-track flex-grow-1" style="max-width:150px;">
                                <div class="bar-fill ${s.studentId eq student.studentId ? 'is-me' : ''}"
                                     data-fill="${topByPoints[0].pointsBalance > 0
                                         ? (s.pointsBalance / topByPoints[0].pointsBalance) * 100 : 0}"></div>
                            </div>
                            <span class="fw-bold text-nowrap" style="font-variant-numeric: tabular-nums;">
                                ${s.pointsBalance} pts
                            </span>
                        </div>
                    </td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
