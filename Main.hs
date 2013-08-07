-- TODO: Modify Easyplot to do time formatting??
import Graphics.EasyPlot
import Data.Time.Clock
import Data.Time.Calendar
import Data.Time.Format
import System.Locale
import Database.HDBC
import Database.HDBC.Sqlite3
import System.Environment

-- type ReviewRow = [[Row Int],[Row String],[Row Double]]

main = do
  args <- getArgs
  let Just command = (lookup (head args) commands)
  command (tail args)

-- Takes the arguments and does an action block based on it
commands :: [(String, [String] -> IO () )]
commands = [("add", doAddReview),
            ("show", doShowReviews),
            ("create", doCreateTable)
            ]

doCreateTable :: [String] -> IO ()
doCreateTable [tableName] = do
  db <- connectSqlite3 "tracking.sqlite3"
  run db ("create table " ++ tableName ++ " (id INTEGER PRIMARY KEY, date DATE, amt FLOAT, to_date FLOAT)") []
  -- TODO: Add confirmation or error message
  return ()

doShowReviews :: [String] -> IO ()
doShowReviews _ = do
  db <- connectSqlite3 "tracking.sqlite3"
  r <- quickQuery' db "select * from reviews" []
  t <- today
  plot' [Debug] X11 $ [Data2D [Title "Reviews"] [] (getDateNumAmountTuples t r) ]
  return ()

-- Takes the rest of the args
-- and adds a review based on them.
doAddReview :: [String] -> IO ()
doAddReview [dateString, amtString] = do
  db <- connectSqlite3 "tracking.sqlite3"
  t <- today
  let date = if dateString == "t"
      then t
      else addDays (-1) t
  addReview db date (read amtString :: Double)

-- Note: doesn't work b/c of id column
addReview :: Connection -> Day -> Double -> IO ()
addReview c d a = do
  run c "INSERT INTO reviews VALUES (NULL,?,?)" [toSql d, toSql a]
  commit c

today :: IO Day
today = getCurrentTime >>= return . utctDay

-- Want a function to zip from a list of rows to
-- a list of plot tuples.
getDateAmountTuples :: Day -> [[SqlValue]] -> [(Day,Double)]
getDateAmountTuples defaultDay list = map (getDateAmountTuple defaultDay) list

getDateAmountTuple :: Day -> [SqlValue] -> (Day, Double)
getDateAmountTuple defaultDay [a,b,c] = ( (fromSql b) :: Day, (fromSql c) :: Double)
getDateAmountTuple defaultDay _ = (defaultDay, 0.0 )

toGnuplotDateString :: Day -> String
toGnuplotDateString d = formatTime defaultTimeLocale "%Y%m%d" d
                        where locale = defaultTimeLocale

getDateNumAmountTuples :: Day -> [[SqlValue]] -> [(Double, Double)]
getDateNumAmountTuples defaultDay = 
  map $ getDateNumAmountTuple . (getDateAmountTuple defaultDay)

getDateNumAmountTuple :: (Day, Double) -> (Double, Double)
getDateNumAmountTuple (d,a) = (read (toGnuplotDateString d) :: Double, a)

