# Beijing Real Estate Investment Analysis

## Project Overview

This project is part of a group assignment for a course in NUS -- BT2102 Data Management and Visualisation

This project explores investment opportunities in the Beijing residential property market using historical housing transaction data. The objective was to identify property characteristics associated with changing market values and develop a data-driven approach to identifying potentially undervalued properties.

Working with a dataset of approximately **297,694 property transactions**, our group investigated two main investment strategies:

1. Identifying property characteristics associated with stronger price appreciation.
2. Identifying potentially undervalued properties by comparing actual transaction prices against model-estimated prices.

My primary contribution was the development of the data preprocessing and valuation methodology, including exploratory data analysis, feature transformations, linear regression modelling, and the classification of properties into valuation tiers.

## My Individual Contributions

My main contributions covered the data preparation and valuation framework, corresponding primarily to **slides 5–26** of the group presentation.

### 1. Data Cleaning and Preprocessing

Prepared the raw Beijing housing transaction dataset for analysis using R.

Key preprocessing steps included:

- Handling missing values, particularly for Days on Market (DOM), where missing observations were imputed using the median.
- Removing irrelevant variables and observations with missing values in relevant fields.
- Cleaning inconsistent data types and correcting incorrectly recorded values.
- Extracting transaction years from transaction dates to create a `tradeYear` variable.
- Converting categorical variables into appropriate factor representations.
- Removing years with insufficient transaction observations to improve the reliability of subsequent analysis.

After preprocessing, the dataset contained approximately 297,694 observations.

### 2. Exploratory Data Analysis and Feature Transformations

Conducted exploratory data analysis to understand the distributions and relationships between housing characteristics and transaction prices.

The analysis covered variables such as:

- Property size and room configurations.
- Building type and structure.
- Construction year and renovation condition.
- District and accessibility to subway stations.
- Listing visibility and Days on Market.

Highly skewed numerical variables were log-transformed before modelling to reduce skewness and improve their suitability for linear regression.

### 3. Linear Regression-Based Property Valuation

Designed and developed a multivariable linear regression model to estimate property prices based on their characteristics.

An important consideration in the methodology was to account for the influence of multiple variables simultaneously, rather than examining property characteristics in isolation.

For example, property prices generally increase over time due to broader market movements. By including `tradeYear` as an explanatory variable, the model accounts for differences associated with the transaction period when estimating the relationships between other property characteristics and prices.

This approach provides a more meaningful basis for comparing properties with different characteristics and transaction dates.

The model's predicted prices were subsequently used as benchmarks for evaluating individual transactions.

### 4. Identifying Potentially Undervalued and Overpriced Properties

Compared actual transaction prices against model-predicted prices by calculating the residual for each property:

`Residual = Actual Price - Predicted Price`

Properties with negative residuals were transacted below their model-estimated prices, while properties with positive residuals were transacted above their estimates.

To translate these residuals into actionable investment insights, I developed a five-tier valuation classification using standard deviation thresholds:

| Valuation category | Classification |
|---|---|
| Undervalued | Residual below mean − 1.5 SD |
| Slightly undervalued | Mean − 1.5 SD to mean − 0.5 SD |
| Evenly priced | Mean ± 0.5 SD |
| Slightly overpriced | Mean + 0.5 SD to mean + 1.5 SD |
| Overpriced | Residual above mean + 1.5 SD |

This allowed us to systematically distinguish properties trading below or above their estimated market prices, rather than relying on absolute transaction prices alone.

### 5. Developing a Price Index

Also developed a Price Index, defined as:

`Price Index = Actual Price / Predicted Price`

By normalising actual prices against model-predicted prices, this measure helps account for differences in property characteristics and transaction periods.

It provides a basis for examining relative price movements across different years and districts, helping identify changes in market valuations beyond differences in the types of properties being transacted.

## Key Findings and Project Conclusions

The group's broader analysis produced several investment insights:

**Property characteristics and price movements**

- Luxury properties, particularly bungalows, six-bedroom properties and properties with three living rooms, exhibited greater price volatility.
- District 13 showed a continuing trend of relative overvaluation.
- Properties with different building structures displayed varying valuation trends, with brick-and-wood and steel structures identified as less attractive investment segments.
- Newer properties generally commanded higher predicted prices, while better renovation conditions helped mitigate the depreciation associated with property age.

**Identifying potentially undervalued properties**

- Properties aged 25 years or older were overrepresented among the undervalued category, suggesting a potential investment opportunity.
- Older properties were found to sell faster than newer properties in the group's demand analysis, challenging the assumption that their lower valuations necessarily reflected weaker demand.
- However, undervalued properties exhibited substantially longer average Days on Market (DOM), indicating that some potentially undervalued transactions could carry liquidity risks.

**Overall investment recommendation**

The group recommended prioritising older properties with relatively low renovation conditions but sound structural characteristics, while using Days on Market as an additional screening criterion.

In particular, targeting properties aged 25 years or older with DOM of 50 days or less was proposed as a way to capture potential valuation opportunities while reducing exposure to properties with liquidity issues.

## Methodology and Analytical Approach

The main analytical workflow developed for my contribution can be summarised as follows:

1. Raw transaction data
2. Data cleaning and preprocessing
3. Exploratory data analysis
4. Feature transformation and preparation
5. Multivariable linear regression
6. Predicted price estimation
7. Residual analysis and five-tier valuation classification
8. Price Index construction

The resulting valuation framework provided the foundation for the group's subsequent investigation into property characteristics, market movements and investment selection.

## Tools and Technologies

- **R:** Data cleaning, preprocessing, exploratory data analysis, feature transformations and statistical modelling.
- **Linear Regression:** Estimating property prices based on multiple explanatory variables.
- **Statistical Analysis:** Residual analysis, standard deviation-based classification and hypothesis testing.
- **Data Visualisation:** Exploring variable distributions, price movements and valuation differences.

## Limitations

- The analysis uses historical transaction data and does not guarantee future property price movements.
- Model-estimated prices represent expected prices conditional on the included variables, rather than definitive intrinsic property values.
- Potential undervaluation does not necessarily imply an attractive investment, as factors such as liquidity, property condition and unobserved characteristics may also influence transaction prices.
- Findings are subject to the limitations of the available dataset and the assumptions of the regression model.

## Acknowledgements

This was a collaborative group project completed with three other team members. The full presentation represents the combined work of all four members, while the code included in this repository focuses on my individual contributions.

