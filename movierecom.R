# Load libraries
library(recommenderlab)
library(ggplot2)                       
library(data.table)
library(reshape2)
library(dplyr)

# Set working directory
setwd("C:/Users/dhanu/Downloads/New/dhanush")

# Reading data
movie_data <- read.csv("movies.csv", stringsAsFactors = FALSE)
rating_data <- read.csv("ratings.csv")

# Extracting movie genres
movie_genre <- as.data.frame(movie_data$genres, stringsAsFactors = FALSE)
movie_genre2 <- as.data.frame(tstrsplit(movie_genre[, 1], '[|]', type.convert = TRUE), stringsAsFactors = FALSE) 

# Creating genre matrix
list_genre <- c("Action", "Adventure", "Animation", "Children", "Comedy", "Crime", "Documentary", "Drama", "Fantasy",
                "Film-Noir", "Horror", "Musical", "Mystery", "Romance", "Sci-Fi", "Thriller", "War", "Western")
genre_mat1 <- matrix(0, nrow(movie_genre2) + 1, 18)
genre_mat1[1,] <- list_genre
colnames(genre_mat1) <- list_genre

# Populating genre matrix
for (index in 1:nrow(movie_genre2)) {
  for (col in 1:ncol(movie_genre2)) {
    gen_col = which(genre_mat1[1,] == movie_genre2[index, col]) 
    genre_mat1[index + 1, gen_col] <- 1
  }
}

# Creating the search matrix
SearchMatrix <- cbind(movie_data[, 1:2], genre_mat1[-1,])

# Reading and pre-processing rating data
ratingMatrix <- dcast(rating_data, userId ~ movieId, value.var = "rating", na.rm = FALSE)
ratingMatrix <- as.matrix(ratingMatrix[, -1]) 
ratingMatrix <- as(ratingMatrix, "realRatingMatrix")

# Explore data and visualize
movie_views <- colCounts(ratingMatrix) 
table_views <- data.frame(movie = names(movie_views), views = movie_views) 
table_views <- table_views[order(table_views$views, decreasing = TRUE), ] 

# Visualization (Bar plot for Total Views of the Top Films)
ggplot(table_views[1:6, ], aes(x = reorder(movie, -views), y = views)) +
  geom_bar(stat = "identity", fill = 'steelblue') +
  geom_text(aes(label = views), vjust = -0.3, size = 3.5) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Total Views of the Top Films") + xlab("Movie Name") +
  scale_x_discrete(labels = movie_data[movie_data$movieId %in% table_views[1:6, ]$movie, ]$title)

# Subset data for analysis
movie_ratings <- ratingMatrix[rowCounts(ratingMatrix) > 50, colCounts(ratingMatrix) > 50]

# Visualization (Distribution of Average Ratings per User)
average_ratings <- rowMeans(movie_ratings)
qplot(average_ratings, fill = I("steelblue"), col = I("red")) +
  ggtitle("Distribution of the Average Rating per User")

# Building recommendation model
recommen_model <- Recommender(data = movie_ratings, method = "IBCF", parameter = list(k = 30))

# Making predictions
top_recommendations <- 10 
predicted_recommendations <- predict(object = recommen_model, newdata = movie_ratings, n = top_recommendations)

# Analyzing recommendations
recommendation_matrix <- sapply(predicted_recommendations@items,
                                function(x){ as.integer(colnames(movie_ratings)[x]) }) 

# Visualization (Distribution of the Number of Recommended Items)
number_of_items <- factor(table(recommendation_matrix))
chart_title <- "Distribution of the Number of Items for IBCF"
qplot(number_of_items, fill = I("purple"), col = I("red")) + ggtitle(chart_title)

# Ask the user for input
user_genre <- "Action"

# Filter movies based on the user-specified genre
selected_genre_movies <- movie_data[grep(user_genre, movie_data$genres, ignore.case = TRUE), ]

# Filter ratings for the selected movies
selected_genre_ratings <- rating_data[rating_data$movieId %in% selected_genre_movies$movieId, ]

# Calculate average ratings for each movie
average_ratings_genre <- aggregate(rating ~ movieId, data = selected_genre_ratings, FUN = mean)

# Merge with movie data to get movie titles
average_ratings_genre <- merge(average_ratings_genre, movie_data, by = "movieId")

# Sort by average rating in descending order
top_genre_movies <- average_ratings_genre[order(average_ratings_genre$rating, decreasing = TRUE), ]

# Select the top 10 movies
top10_genre_movies <- head(top_genre_movies, 5)

# Visualization (Bar plot for Top 10 Movies from the User-specified Genre)
ggplot(top10_genre_movies, aes(x = reorder(title, -rating), y = rating)) +
  geom_bar(stat = "identity", fill = 'pink') +
  geom_text(aes(label = round(rating, 2)), vjust = -0.3, size = 3.5) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle(paste("Top 10 Movies in the", user_genre, "Genre with Ratings")) +
  xlab("Movie Name")




# Merge data to get movie genres
movie_data <- merge(ratings, movies, by = "movieId")

# Define the four genres of interest
selected_genres <- c("Action", "Comedy", "Drama", "Sci-Fi")

# Filter data for the selected genres
filtered_data <- movie_data %>%
  filter(genres %in% selected_genres, rating > 2)

# Create a box plot
ggplot(filtered_data, aes(x = genres, y = rating)) +
  geom_boxplot(fill = 'yellow', color = 'black') +
  ggtitle("Box Plot of Ratings > 3 for Selected Genres") +
  xlab("Genre") +
  ylab("Rating")

movie_data <- merge(ratings, movies, by = "movieId")

# Define the four genres of interest
selected_genres <- c("Action", "Comedy", "Drama", "Sci-Fi")

# Filter data for the selected genres
filtered_data <- movie_data %>%
  filter(genres %in% selected_genres, rating > 3)

# Create a box and whisker plot
ggplot(filtered_data, aes(x = genres, y = rating)) +
  geom_boxplot(fill = 'green', color = 'black') +
  ggtitle("Box and Whisker Plot of Ratings > 3 for Selected Genres") +
  xlab("Genre") +
  ylab("Rating")

movie_data <- merge(ratings, movies, by = "movieId")

# Calculate the number of ratings for each movie
rating_counts <- movie_data %>%
  group_by(movieId) %>%
  summarise(num_ratings = n(),
            avg_rating = mean(rating))

# Create a scatter plot
ggplot(rating_counts, aes(x = num_ratings, y = avg_rating)) +
  geom_point(color = 'red') +
  ggtitle("Scatter Plot of Number of Ratings vs. Average Rating") +
  xlab("Number of Ratings") +
  ylab("Average Rating")