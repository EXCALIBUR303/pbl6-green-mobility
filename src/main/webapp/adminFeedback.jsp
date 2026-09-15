<%@ include file="/WEB-INF/jspf/adminGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.FeedbackDAO" %>
<%@ page import="com.woxsen.greenmobility.model.RideFeedback" %>
<%@ page import="java.util.List" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    String pageTitle = "Feedback Inbox";
    List<RideFeedback> feedback = new FeedbackDAO().getAllFeedback();
    request.setAttribute("feedback", feedback);
    request.setAttribute("areasToImprove", new FeedbackDAO().getAreasToImprove());
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<h1 class="page-title text-forest mb-1">Feedback inbox</h1>
<p class="text-secondary mb-4">Every post-ride rating and pre-cancellation reason, newest first.</p>

<c:if test="${not empty areasToImprove}">
    <div class="card p-4 mb-4">
        <span class="section-label d-block mb-3"><i class="bi bi-megaphone me-1"></i>Areas to improve, by category</span>
        <div class="d-flex flex-wrap gap-2">
            <c:forEach var="a" items="${areasToImprove}">
                <span class="pill pill-muted">
                    ${a.category} &middot; ${a.mentions}
                    <c:if test="${not empty a.avgRating}">
                        &middot; <i class="bi bi-star-fill" style="color:var(--amber);"></i>
                        <fmt:formatNumber value="${a.avgRating}" maxFractionDigits="1"/>
                    </c:if>
                </span>
            </c:forEach>
        </div>
    </div>
</c:if>

<div class="card p-4">
    <c:choose>
        <c:when test="${empty feedback}">
            <div class="empty-state">
                <div class="glyph"><i class="bi bi-chat-square"></i></div>
                <p class="text-secondary mt-3 mb-0">No feedback submitted yet.</p>
            </div>
        </c:when>
        <c:otherwise>
            <div class="d-flex flex-column gap-3" data-reveal>
                <c:forEach var="f" items="${feedback}">
                    <div class="tl-item" style="padding-bottom: 1rem; border-bottom: 1px solid var(--border);">
                        <div class="d-flex flex-wrap justify-content-between align-items-start gap-2 mb-1">
                            <div>
                                <span class="fw-semibold">${f.studentName}</span>
                                <span class="small text-muted ms-1">${f.studentEmail}</span>
                            </div>
                            <div class="d-flex align-items-center gap-2">
                                <span class="pill ${f.kind eq 'CANCELLATION' ? 'pill-muted' : 'pill-eco'}">
                                    ${f.kind eq 'CANCELLATION' ? 'Cancellation' : 'Post-ride'}
                                </span>
                                <c:if test="${not empty f.rating}">
                                    <span class="pill pill-soon">
                                        <i class="bi bi-star-fill"></i>${f.rating}/5
                                    </span>
                                </c:if>
                            </div>
                        </div>
                        <div class="small mb-1">
                            <span class="fw-semibold" style="color: var(--forest-600);">${f.category}</span>
                            <span class="text-muted ms-2">
                                <fmt:formatDate value="${f.createdAt}" pattern="dd MMM yyyy, hh:mm a"/>
                            </span>
                        </div>
                        <c:if test="${not empty f.comment}">
                            <p class="small text-secondary mb-0">"${f.comment}"</p>
                        </c:if>
                    </div>
                </c:forEach>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
