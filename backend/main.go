package main

import (
	"bookshelf/internal/database"
	"bookshelf/internal/handler"
	"bookshelf/internal/middleware"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
	"github.com/joho/godotenv"

	_ "github.com/lib/pq"
)

var router *chi.Mux

func main() {
	fmt.Println("Hello World")

	godotenv.Load(".env")

	var portString string = os.Getenv("PORT")
	if portString == "" {
		log.Fatal("PORT is not found in the environment")
	}

	dbUrl := os.Getenv("DB_URL")
	if dbUrl == "" {
		log.Fatal("DB_URL environment variable is not set")
	}

	db, err := sql.Open("postgres", dbUrl)
	if err != nil {
		log.Fatal(err)
	}

	dbQueries := database.New(db)

	apiConfig := handler.ApiConfig{
		DB: dbQueries,
	}

	fmt.Println("PORT: ", portString)

	router = chi.NewRouter()

	router.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Authorization", "Content-Type"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           3600,
	}))

	v1Router := chi.NewRouter()
	v1Router.Get("/healthz", handler.Healthz)
	v1Router.Post("/user/register", apiConfig.Register)
	v1Router.Post("/user/login", apiConfig.Login)

	// Router that need middleware authenticator
	v1Router.Group(func(secureRouter chi.Router) {
		secureRouter.Use(middleware.AuthMiddleware)
		secureRouter.Get("/books", apiConfig.GetBooks)
		secureRouter.Post("/books", apiConfig.AddBooks)
		secureRouter.Put("/books", apiConfig.EditBooks)
		secureRouter.Post("/books/delete", apiConfig.DeleteBooks)
		secureRouter.Delete("/book/{bookId}", apiConfig.DeleteBook)
	})

	router.Mount("/api/v1", v1Router)

	srv := &http.Server{
		Handler: router,
		Addr:    ":" + portString,
	}

	log.Printf("Server starting on PORT: %v", portString)
	err = srv.ListenAndServe()
	if err != nil {
		log.Fatal(err)
	}
}
