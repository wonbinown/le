<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<div class="header">
  <div class="logo"><a href="${pageContext.request.contextPath}/main">📚 BookMarket</a></div>
  
  <div class="nav">
    <input type="text" placeholder="검색어 입력" />
    
    <div class="user-menu">
      <c:if test="${empty sessionScope.loginId}">
        <a href="${pageContext.request.contextPath}/loginForm">로그인</a>
        <a href="${pageContext.request.contextPath}/register">회원가입</a>
      </c:if>
      <c:if test="${not empty sessionScope.loginId}">
        <a href="${pageContext.request.contextPath}/cart">🛒 장바구니</a>
        <a href="${pageContext.request.contextPath}/mypage">👤 내 정보</a>
        <form action="${pageContext.request.contextPath}/logout" method="post" style="display:inline;">
          <button type="submit">로그아웃</button>
        </form>
      </c:if>
    </div>
  </div>
</div>
