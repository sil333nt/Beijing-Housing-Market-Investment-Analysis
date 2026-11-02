install.packages("readxl")
library(readxl)

House <- read_excel("~/Documents/BT2102/BeijingHousingPrices-1.xlsx")

library(stringr)

House$floorrange <- str_extract(House$floor, "^[A-Za-z]+")
House$floor <- as.numeric(str_extract(House$floor, "\\d+$"))

colSums(is.na(House))

str(House)

temp <- na.omit(House$DOM)
summary(temp)
boxplot(temp, horizontal = TRUE, main = "Boxplot of DOM")
med <- median(temp)
House$DOM[is.na(House$DOM)] <- med

cols_to_fix <- c("buildingType", "constructionTime")

for (col in cols_to_fix) {
  # Force non-numeric strings to NA automatically
  House[[col]] <- suppressWarnings(as.numeric(House[[col]]))
}

swap_idx <- with(House,
                 (
                   (!is.na(bathRoom) & !is.na(constructionTime) &
                      bathRoom >= 1000 & constructionTime < 100)
                 ) |
                   (
                     is.na(bathRoom) & !is.na(constructionTime) & constructionTime < 100
                   )
)

# Swap safely
temp <- House$bathRoom[swap_idx]
House$bathRoom[swap_idx] <- House$constructionTime[swap_idx]
House$constructionTime[swap_idx] <- temp

# Fix the 3 factor/numeric category columns
cols_factor <- c("buildingType", "renovationCondition", "buildingStructure")

for (col in cols_factor) {
  # Convert factors to numeric if needed
  if (is.factor(House[[col]])) {
    House[[col]] <- as.numeric(as.character(House[[col]]))
  }
  
  # Set invalid (< 1) values to NA
  House[[col]][House[[col]] < 1] <- NA
}

# Fix ladderRatio: 0 → NA
House$ladderRatio[House$ladderRatio == 0] <- NA

# Set extremely large values to NA
House$ladderRatio[House$ladderRatio > 1e2] <- NA

House <- subset(House, select = -c(url, id, Cid))

colSums(is.na(House))

House <- na.omit(House)

install.packages("writexl")
library(writexl)

write_xlsx(House, "House_cleaned.xlsx")

House$livingRoom <- as.factor(House$livingRoom)
House$drawingRoom <- as.factor(House$drawingRoom)
House$kitchen <- as.factor(House$kitchen)
House$bathRoom <- as.factor(House$bathRoom)
House$buildingType <- as.factor(House$buildingType)
House$renovationCondition <- as.factor(House$renovationCondition)
House$buildingStructure <- as.factor(House$buildingStructure)
House$elevator <- as.factor(House$elevator)
House$fiveYearsProperty <- as.factor(House$fiveYearsProperty)
House$subway <- as.factor(House$subway)
House$district <- as.factor(House$district)
House$floorrange <- as.factor(House$floorrange)
House$constructionTime <- as.factor(House$constructionTime)
House$floor <- as.factor(House$floor)

House$tradeYear <- as.numeric(format(House$tradeTime, "%Y"))
House$tradeYear <- as.factor(House$tradeYear)

House <- House[!(House$tradeYear %in% c(2002, 2003, 2009)), ]

# Select only numeric variables
numeric_data <- House[, c("DOM", "followers", "square", "ladderRatio", "communityAverage", "price")]
pairs(numeric_data)
pairs(log1p(numeric_data))

par(mfrow = c(3, 2))  # adjust rows/cols to fit number of variables

# Loop through each numeric variable and plot
for (col in names(numeric_data)) {
  hist(numeric_data[[col]], 
       main = paste("Histogram of", col), 
       xlab = col, 
       col = "skyblue", 
       border = "white",
       breaks = 50)
}

# Plot all numeric columns as boxplots
par(mfrow = c(3, 2))
for (col in names(numeric_data)) {
  boxplot(numeric_data[[col]],
          main = paste("Boxplot of", col),
          col = "lightblue",
          border = "gray40",
          ylab = col)
}

cor_matrix <- cor(numeric_data, use = "complete.obs")
print(cor_matrix)

library(reshape2)
library(ggplot2)

cor_melt <- melt(cor_matrix)

# Plot with correlation values displayed
ggplot(cor_melt, aes(Var1, Var2, fill = value)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(value, 2)), size = 3, color = "black") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                       midpoint = 0, limit = c(-1, 1),
                       name = "Correlation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
        axis.title.x = element_blank(),
        axis.title.y = element_blank()) +
  labs(title = "Correlation Heatmap of Numerical Variables")

ggplot(House, aes_string(x = "tradeYear", y = "price_index")) +
  geom_boxplot(outlier.alpha = 0.3, fill = "#69b3a2") +
  labs(
    title = paste("Price Distribution by", "tradeYear"),
    x = "tradeYear",
    y = "Price"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold", hjust = 0.5)
  )


# Fit model including year
lm_model6 <- lm(log(price) ~ DOM + followers + square + tradeYear +
                  drawingRoom + kitchen + bathRoom + floor + buildingType +
                  constructionTime + renovationCondition +
                  ladderRatio + elevator + fiveYearsProperty + subway + 
                  district + communityAverage + floorrange, data = House)
summary(lm_model6)

# Predicted log(price)
House$pred_logprice <- predict(lm_model6)

# Convert predicted log(price) back to original price scale
House$pred_price <- expm1(House$pred_logprice)  # inverse of log1p()

# Compute residuals (actual - predicted)
House$residual <- House$price - House$pred_price

summary(House$residual)
hist(House$residual, breaks = 50, main = "Distribution of Residuals", xlab = "Residual (Actual - Predicted)")

res_mean <- mean(House$residual, na.rm = TRUE)
res_sd <- sd(House$residual, na.rm = TRUE)

House$valuation <- cut(
  House$residual,
  breaks = c(-Inf, res_mean - 1.5*res_sd, res_mean - 0.5*res_sd, 
             res_mean + 0.5*res_sd, res_mean + 1.5*res_sd, Inf),
  labels = c("Undervalued", "Slightly undervalued", "Evenly priced", 
             "Slightly overpriced", "Overpriced")
)
table(House$valuation)

library(ggplot2)
ggplot(House, aes(x = pred_price, y = price, color = valuation)) +
  geom_point(alpha = 0.6) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(title = "Predicted vs Actual Prices", x = "Predicted Price", y = "Actual Price")

sum(residuals(lm_model6)^2)

# Get coefficient table
coef_summary <- coef(lm_model6)

# Extract coefficient names and CIs for tradeYear terms
year_terms <- grep("tradeYear", names(coef_summary), value = TRUE)
year_coef <- coef(lm_model6)[year_terms]
year_ci <- confint(lm_model6)[year_terms, ]

years <- as.numeric(gsub("tradeYear", "", year_terms))
df_year <- data.frame(
  Year = years,
  Estimate = year_coef,
  Lower = year_ci[, 1],
  Upper = year_ci[, 2]
)

# Order by year
df_year <- df_year[order(df_year$Year), ]

df_year$PctChange <- (exp(df_year$Estimate) - 1) * 100
df_year$LowerPct <- (exp(df_year$Lower) - 1) * 100
df_year$UpperPct <- (exp(df_year$Upper) - 1) * 100

# Plot % change
plot(df_year$Year, df_year$PctChange, type = "b", pch = 19,
     xlab = "Year",
     ylab = "% price change relative to baseline year",
     main = "Inflation / Time Effect on Beijing Property Prices",
     ylim = range(c(df_year$LowerPct, df_year$UpperPct)))

# Add shaded CI area (using % values)
polygon(
  c(df_year$Year, rev(df_year$Year)),
  c(df_year$LowerPct, rev(df_year$UpperPct)),
  col = rgb(0.2, 0.4, 0.8, 0.2), border = NA
)

# Re-plot line and points
lines(df_year$Year, df_year$PctChange, lwd = 2, col = "blue")
points(df_year$Year, df_year$PctChange, pch = 19, col = "blue")

# Baseline line
abline(h = 0, lty = 2, col = "gray40")

#boxplot
boxplot(price ~ tradeYear, data = House,
        main = "Distribution of Property Prices by Year",
        xlab = "Trade Year", ylab = "Price",
        col = "skyblue", border = "gray40")


lm_model9 <- lm(log1p(price) ~ log1p(DOM) + log1p(followers) + log1p(square) + livingRoom 
                + tradeYear + drawingRoom + kitchen + bathRoom + floor + buildingType 
                + constructionTime + renovationCondition + buildingStructure 
                + log1p(ladderRatio) + elevator + fiveYearsProperty + subway 
                + district + log1p(communityAverage) + floorrange, data = House)
summary(lm_model9)
plot(lm_model9)

# Predicted log(price)
House$pred_logprice <- predict(lm_model9)

# Convert predicted log(price) back to original price scale
House$pred_price <- expm1(House$pred_logprice)  # inverse of log1p()

# Compute residuals (actual - predicted)
House$residual <- House$price - House$pred_price

summary(House$residual)
hist(House$residual, breaks = 50, main = "Distribution of Residuals", xlab = "Residual (Actual - Predicted)")

res_mean <- mean(House$residual, na.rm = TRUE)
res_sd <- sd(House$residual, na.rm = TRUE)

House$valuation <- cut(
  House$residual,
  breaks = c(-Inf, res_mean - 1.5*res_sd, res_mean - 0.5*res_sd, 
             res_mean + 0.5*res_sd, res_mean + 1.5*res_sd, Inf),
  labels = c("Undervalued", "Slightly undervalued", "Evenly priced", 
             "Slightly overpriced", "Overpriced")
)
table(House$valuation)

library(ggplot2)
ggplot(House, aes(x = pred_price, y = price, color = valuation)) +
  geom_point(alpha = 0.6) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(title = "Predicted vs Actual Prices", x = "Predicted Price", y = "Actual Price")

write_xlsx(House, "House_cleaned_w_valuation.xlsx")

library(dplyr)
library(ggplot2)

# Compute mean price by district and tradeYear
price_trend <- House %>%
  group_by(district, tradeYear) %>%
  summarise(mean_price = mean(price, na.rm = TRUE)) %>%
  ungroup()

# Plot
ggplot(price_trend, aes(x = tradeYear, y = mean_price, color = district, group = district)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Average Property Price Over Time by District",
    x = "Trade Year",
    y = "Average Price"
  ) +
  theme_minimal() +
  theme(legend.position = "right")

ggplot(price_trend, aes(x = tradeYear, y = mean_price, color = district, group = district)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_y_log10() +
  labs(
    title = "Log-Scaled Average Property Price Over Time by District",
    x = "Trade Year",
    y = "Average Price (log scale)"
  ) +
  theme_minimal()

price_trend <- House %>%
  group_by(district, tradeYear) %>%
  summarise(mean_price = mean(price, na.rm = TRUE)) %>%
  arrange(district, tradeYear) %>%
  group_by(district) %>%
  mutate(rel_price = mean_price / first(mean_price)) %>%
  ungroup()

ggplot(price_trend, aes(x = tradeYear, y = rel_price, color = district, group = district)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Relative Price Growth Over Time by District",
    x = "Trade Year",
    y = "Relative Price (Indexed to First Year = 1)"
  ) +
  theme_minimal()

district_summary <- House %>%
  group_by(district) %>%
  summarise(
    mean_community = mean(communityAverage, na.rm = TRUE),
    total_community = sum(communityAverage, na.rm = TRUE),
    n_communities = n()
  ) %>%
  arrange(desc(mean_community))  # or arrange by total_community if preferred

district_summary

price_trend <- House %>%
  group_by(valuation, tradeYear) %>%
  summarise(mean_price = mean(price, na.rm = TRUE)) %>%
  arrange(valuation, tradeYear) %>%
  group_by(valuation) %>%
  mutate(rel_price = mean_price / first(mean_price)) %>%
  ungroup()

ggplot(price_trend, aes(x = tradeYear, y = rel_price, color = valuation, group = valuation)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Relative Price Growth Over Time by valuation",
    x = "Trade Year",
    y = "Relative Price (Indexed to First Year = 1)"
  ) +
  theme_minimal()

House %>%
  count(tradeYear, valuation) %>%
  group_by(tradeYear) %>%
  mutate(share = n / sum(n)) %>%
  ggplot(aes(x = tradeYear, y = share, fill = valuation)) +
  geom_col(position = "fill") +
  labs(title = "Share of Valuation Categories Over Time", y = "Share", x = "Year") +
  theme_minimal()

ggplot(House, aes(x = factor(tradeYear), y = price, fill = valuation)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.7) +
  coord_cartesian(ylim = quantile(House$price, c(0.05, 0.95), na.rm = TRUE)) +  # trim extremes for readability
  labs(
    title = "Distribution of Prices by Valuation and Year",
    x = "Trade Year",
    y = "Price"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

House$price_index <- House$price / House$pred_price

# 4️⃣ Inspect the distribution
summary(House$price_index)
hist(House$price_index, main = "Quality-Adjusted Price Index", xlab = "Actual / Predicted Price Ratio")

House %>%
  group_by(tradeYear) %>%
  summarise(mean_index = mean(price_index, na.rm = TRUE)) %>%
  ggplot(aes(x = tradeYear, y = mean_index)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 2) +
  labs(
    title = "Quality-Adjusted Price Trend Over Time",
    x = "Trade Year",
    y = "Mean Actual / Predicted Price"
  ) +
  theme_minimal()

House %>%
  group_by(tradeYear, valuation) %>%
  summarise(mean_index = mean(price_index, na.rm = TRUE)) %>%
  ggplot(aes(x = tradeYear, y = mean_index, color = valuation, group = valuation)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Quality-Adjusted Price Index by Valuation Over Time",
    x = "Trade Year",
    y = "Actual / Predicted Price Ratio"
  ) +
  theme_minimal()

# Ensure all required columns exist
House_analysis <- House %>%
  filter(!is.na(tradeYear), !is.na(valuation), !is.na(price_index)) %>%
  mutate(log_index = log(price_index))  # log-transform for growth modelling

growth_model <- lm(log_index ~ tradeYear * valuation, data = House_analysis)
summary(growth_model)

library(ggeffects)  # for easy marginal effects visualization

pred <- ggpredict(growth_model, terms = c("tradeYear", "valuation"))

anova(growth_model)

House_analysis <- House_analysis %>%
  mutate(tradeYear_num = as.numeric(as.character(tradeYear)))  # convert factor -> numeric
growth_model <- lm(log_index ~ tradeYear_num * valuation, data = House_analysis)
library(emmeans)

# Estimate annual slope for each valuation group
em_trends_val <- emtrends(growth_model, ~ valuation, var = "tradeYear_num")
summary(em_trends_val)

# Compare slopes pairwise
pairs(em_trends_val)

# Extract slopes and CIs
slopes <- summary(em_trends_val, infer = TRUE)  # includes lower/upper CI

ggplot(slopes, aes(x = valuation, y = tradeYear_num.trend, color = valuation)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Annual Growth Rate of Quality-Adjusted Price by Valuation",
    x = "Valuation Group",
    y = "Estimated Annual Slope (log price_index)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

slopes <- slopes %>%
  mutate(pct_growth = (exp(tradeYear_num.trend) - 1) * 100,
         pct_lower = (exp(lower.CL) - 1) * 100,
         pct_upper = (exp(upper.CL) - 1) * 100)

ggplot(slopes, aes(x = valuation, y = pct_growth, color = valuation)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = pct_lower, ymax = pct_upper), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Annual % Growth of Quality-Adjusted Price by Valuation",
    x = "Valuation Group",
    y = "Annual Growth (%)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

House %>%
  group_by(tradeYear, subway) %>%
  summarise(mean_index = mean(price_index, na.rm = TRUE)) %>%
  ggplot(aes(x = tradeYear, y = mean_index, color = subway, group = subway)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Quality-Adjusted Price Index by subway Over Time",
    x = "Trade Year",
    y = "Actual / Predicted Price Ratio"
  ) +
  theme_minimal()

write_xlsx(House, "House_w_price_index.xlsx")

ggplot(House, aes(x = factor(subway), y = price, fill = factor(subway))) +
  geom_boxplot(outlier.shape = NA, alpha = 0.7) +
  scale_fill_manual(values = c("#999999", "#56B4E9"), labels = c("No Subway", "Near Subway")) +
  facet_wrap(~ district) +
  labs(
    title = "House Prices by Subway Proximity Across Districts",
    x = "Near Subway Station",
    y = "Price"
  ) +
  theme_bw() +
  theme(legend.position = "bottom")

ggplot(House, aes(x = as.factor(constructionTime), y = price_index)) +
  geom_boxplot(fill = "#69b3a2", outlier.alpha = 0.3) +
  labs(
    title = "Price Index by Construction Year",
    x = "Construction Year",
    y = "Price Index (Actual / Predicted Price)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold", hjust = 0.5)
  )

ggplot(House, aes(x = constructionTime, y = price_index)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "loess", se = TRUE, color = "#1f78b4", fill = "#a6cee3") +
  labs(
    title = "Trend of Price Index by Construction Year",
    x = "Construction Year",
    y = "Price Index (Actual / Predicted Price)"
  ) +
  theme_minimal(base_size = 12)

library(broom)
library(ggplot2)
library(dplyr)

coef_df <- broom::tidy(lm_model9) %>%
  filter(grepl("constructionTime", term)) %>%
  mutate(
    constructionTime = gsub("constructionTime", "", term),
    constructionTime = as.numeric(constructionTime)
  )

# Plot
ggplot(coef_df, aes(x = constructionTime, y = estimate)) +
  geom_line(color = "#1f78b4") +                    # line connecting points
  geom_point(color = "#1f78b4") +                   # points
  geom_smooth(method = "lm", se = FALSE, color = "red") +  # best-fit line
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey40") +  # reference line
  labs(
    title = "Effect of Construction Time on Predicted House Price",
    x = "Construction Time",
    y = "Approx % change in price relative to baseline year 1950"
  ) +
  theme_minimal(base_size = 12)

# Extract coefficients for construction year
coef_summary <- coef(lm_model9)
cons_terms <- grep("constructionTime", names(coef_summary), value = TRUE)
cons_coef <- coef(lm_model9)[cons_terms]

# Convert to percentage change
construction_df <- data.frame(
  Condition = gsub("constructionTime", "", cons_terms),
  Estimate = (exp(cons_coef) - 1) * 100
)

# Reorder by estimated effect
construction_df$Condition <- factor(construction_df$Condition, levels = construction_df$Condition[order(construction_df$Estimate)])

# Plot
library(ggplot2)
ggplot(construction_df, aes(x = Condition, y = Estimate)) +
  geom_line(color = "steelblue", size = 1) +
  geom_point(color = "steelblue", size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "darkred", linetype = "dashed") +
  labs(
    title = "Effect of Construction Year on House Prices",
    x = "Construction Year",
    y = "Approximate % Change in Price (relative to baseline year 1950)"
  ) +
  theme_minimal()

reno_terms <- grep("renovationCondition", names(coef_summary), value = TRUE)
reno_coef <- coef(lm_model9)[reno_terms]

# Convert to percentage change
reno_df <- data.frame(
  Condition = gsub("renovationCondition", "", reno_terms),
  Estimate = (exp(reno_coef) - 1) * 100
)

# Reorder by estimated effect
reno_df$Condition <- factor(reno_df$Condition, levels = reno_df$Condition[order(reno_df$Estimate)])

# Plot
library(ggplot2)
ggplot(reno_df, aes(x = Condition, y = Estimate, group = 1)) +
  geom_line(color = "steelblue") +
  geom_point(color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    title = "Effect of Renovation Condition on Property Prices",
    x = "Renovation Condition (relative to baseline)",
    y = "Approximate % Change in Price"
  ) +
  theme_minimal()

ggplot(reno_df, aes(x = Condition, y = Estimate, fill = Estimate > 0)) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_fill_manual(values = c("red", "steelblue"), guide = "none") +
  labs(
    title = "Effect of Renovation Condition on House Prices",
    x = "Renovation Condition (relative to baseline)",
    y = "Approximate % Change in Price"
  ) +
  theme_minimal()

coef_summary <- coef(lm_model9)
cons_terms <- grep("constructionTime", names(coef_summary), value = TRUE)
cons_coef <- coef(lm_model9)[cons_terms]

construction_df <- data.frame(
  Condition = gsub("[^0-9]", "", cons_terms),
  Estimate = (exp(cons_coef) - 1) * 100
)

construction_df$Condition <- as.numeric(construction_df$Condition)
construction_df <- rbind(data.frame(Condition = 1950, Estimate = 0), construction_df)

library(ggplot2)
ggplot(construction_df, aes(x = Condition, y = Estimate)) +
  geom_line(color = "steelblue") +
  geom_point(color = "steelblue") +
  geom_smooth(method = "lm", se = FALSE, color = "darkred", linetype = "dashed") +
  labs(
    title = "Effect of Construction Year on House Prices",
    x = "Construction Year",
    y = "Approx. % Change in Price (relative to baseline year 1950)"
  ) +
  theme_minimal()

