package controller;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import mapper.BookMapper;
import model.Book;

@Controller
public class BookController {

    @Autowired
    private BookMapper bookMapper;

    @GetMapping("/bookstore/books")
    public String bookPage(Model model) {
        // 1) DB에서 전체 책 리스트 가져오기
        List<Book> books = bookMapper.findAllBooks();
        // 2) JSP에서 사용할 이름으로 모델에 담기
        model.addAttribute("books", books);
        // 3) 뷰 리턴
        return "bookstore/book"; // /WEB-INF/views/bookstore/book.jsp
    }
}
