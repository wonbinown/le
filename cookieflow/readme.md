# CookieFlow (쿠키 장바구니 데모)

브라우저 **쿠키**에 장바구니를 저장/복원하는 Spring MVC 예제입니다.
`cart` 쿠키에 `{상품ID: 수량}` 맵을 **JSON → URL 인코딩 → Base64**로 저장합니다.

---

## ✨ 핵심 요약

* **쿠키 키**: `cart`
* **포맷**: `Map<Integer,Integer> → JSON → URLEncoder(UTF-8) → Base64`
* **유효기간**: 14일 (`CART_MAX_AGE`)
* **쿠키 Path**: `/cookie` (데모용 · 실제 서비스 경로에 맞게 변경)
* **호환**: v2(Base64) 실패 시 v1(평문 URL-encoded JSON) 재시도
* **주의**: 데모 편의상 `HttpOnly=false` (실서비스는 `true` 권장)

---

## 📁 주요 파일
* `cookieflow/CookieFlowController.java`
  * 장바구니 동작: 보기/담기/수정/삭제/비우기
  * 쿠키 유틸:

    * `readCart(HttpServletRequest)` → 쿠키를 `Map<Integer,Integer>`로 복원
    * `writeCart(HttpServletResponse, Map)` → 맵을 쿠키에 저장
    * `deleteCookie(...)`, `cookieValue(...)`

> JSP(예시): `WEB-INF/views/cookie/list.jsp`, `WEB-INF/views/cookie/cart.jsp`

---

## 🔌 엔드포인트

| Method | Path                             | 설명                  |
| -----: | -------------------------------- | --------------------- |
|    GET | `/cookie/list`                   | 데모 상품 목록         |
|    GET | `/cookie/cart`                   | 장바구니 보기          |
|   POST | `/cookie/add?id=&qty=&redirect=` | 담기(+수량 증가) → 리다이렉트 |
|   POST | `/cookie/update?id=&qty=`        | 수량 변경              |
|   POST | `/cookie/remove?id=`             | 항목 삭제              |
|   POST | `/cookie/clear`                  | 장바구니 비우기        |

> `redirect` 기본값: `/cookie/list`

---

## 🍪 쿠키 데이터 구조

* **논리 데이터(예)**

  ```json
  { "1": 2, "3": 1 }
  ```

  *1번 2개, 3번 1개*
* **저장 파이프라인**
  `Map → JSON → URL 인코딩 → Base64 → Cookie(cart)`
* **읽기 흐름**
  Base64 디코드 실패 시 평문 URL-encoded JSON 파싱 재시도

---

## 🔐 운영/보안 팁

* 실서비스 권장:

  * `c.setHttpOnly(true);` (JS에서 쿠키 조작하지 않을 때)
  * `c.setSecure(true);` (HTTPS)
  * `c.setPath(앱 루트)` 로 실제 경로에 맞추기 (예: `/bookstore`)
* CSRF:
  * 폼/POST 사용 시 CSRF 토큰 포함 또는 예외 경로 설계
  * 쿠키 용량(도메인·키당 \~4KB) 유의 → **아이디/수량 등 최소 정보만 저장**하고, 상세 정보는 서버에서 해석

---

## 🚀 실행

1. 컨트롤러 컴포넌트 스캔에 `cookieflow` 포함
2. 서버 기동 후:

   * `GET /cookie/list` → 상품 목록
   * 담기 후 `GET /cookie/cart` → 장바구니 확인

---

## 🧪 빠른 테스트 플로우

1. `/cookie/list`에서 담기:
   `POST /cookie/add?id=1&qty=1`
2. 수량 변경:
   `POST /cookie/update?id=1&qty=3`
3. 삭제 또는 비우기:
   `POST /cookie/remove?id=1` / `POST /cookie/clear`

---

## 📄 .gitignore (권장)

```
/target/
/build/
/bin/
/out/
.classpath
.project
.settings/
.idea/
*.iml
*.log
.DS_Store
Thumbs.db
```

---
## 📜 LICENSE
kwb
