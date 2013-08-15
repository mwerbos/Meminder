-- TODO make fork of EasyPlot more obviously a fork
import Graphics.EasyPlot
import Data.Time.Clock
import Data.Time.Calendar
import Data.Time.Format
import System.Locale
import Database.HDBC
import Database.HDBC.Sqlite3
import System.Environment

main = do
  args <- getArgs
  let Just command = (lookup (head args) commands)
  command (tail args)

-- Takes the arguments and does an action block based on it
commands :: [(String, [String] -> IO () )]
commands = [("add", addToTable),
            ("show", showTable),
            ("create", createTable),
            ("init", initDatabase),
            ("list", listTables)
            ]

initDatabase :: [String] -> IO ()
initDatabase _ = do
  -- TODO make sure this works even if the file doesn't exist yet
  db <- connectSqlite3 "tracking.sqlite3"
  run db "create table tracking_master (name STRING, x_intercept DATE, per_day FLOAT);" []
  commit db
  return ()

listTables :: [String] -> IO ()
listTables _ = do
  db <- connectSqlite3 "tracking.sqlite3"
  r <- quickQuery' db ("select * from tracking_master") []
  putStrLn "The following items are being tracked in the database:"
  mapM putStrLn (getNames r)
  return ()
  where getNames rowList = map getName rowList
        getName (name:_) = (fromSql name) :: String

createTable :: [String] -> IO ()
createTable [tableName] = do
  -- TODO: use tracking_master table to also add intercept line
  db <- connectSqlite3 "tracking.sqlite3"
  run db ("create table " ++ tableName ++ " (id INTEGER PRIMARY KEY, date DATE, amt FLOAT, to_date FLOAT);") []
  -- TODO make x intercept and per-day customizable
  t <- today
  run db "INSERT into tracking_master VALUES (?,?,?)" [toSql tableName, toSql t, toSql (1.0 :: Double)]
  commit db
  -- TODO: Add confirmation or error message
  return ()

showTable :: [String] -> IO ()
showTable args = do
  -- TODO: use tracking_master table to show desired line
  -- (and margins of error?)
  db <- connectSqlite3 "tracking.sqlite3"
  r <- quickQuery' db ("select * from " ++ (head args)) []
  t <- today
  plot' [Debug] X11 $ [TimeData2D [Title "Reviews", XTime True] [] (getDateAmountTuples t r) ]
  return ()

showReviews :: [String] -> IO ()
showReviews _ = showTable ["reviews"]

-- Takes the rest of the args
-- and adds a review based on them.
addToTable :: [String] -> IO ()
addToTable [tableName, dateString, amtString] = do
  db <- connectSqlite3 "tracking.sqlite3"
  t <- today
  let date = if dateString == "t"
      then t
      else addDays (-1) t
  addItem db tableName date (read amtString :: Double)

-- Note: doesn't work b/c of id column
addItem :: Connection -> String -> Day -> Double -> IO ()
addItem c n d a = do
-- TODO make to_date actually work
  run c ("INSERT INTO " ++ n ++ " VALUES (NULL,?,?,?)") [toSql d, toSql a, toSql a]
  commit c

today :: IO Day
today = getCurrentTime >>= return . utctDay

-- Want a function to zip from a list of rows to
-- a list of plot tuples.
getDateAmountTuples :: Day -> [[SqlValue]] -> [(Day,Double)]
getDateAmountTuples defaultDay list = map (getDateAmountTuple defaultDay) list

getDateAmountTuple :: Day -> [SqlValue] -> (Day, Double)
-- List should be ID, date, amt, to_datet
getDateAmountTuple defaultDay [a,b,c,d] = ( (fromSql b) :: Day, (fromSql c) :: Double)
getDateAmountTuple defaultDay _ = (defaultDay, 0.0 )

toGnuplotDateString :: Day -> String
toGnuplotDateString d = formatTime defaultTimeLocale "%Y%m%d" d
                        where locale = defaultTimeLocale

getDateNumAmountTuples :: Day -> [[SqlValue]] -> [(Double, Double)]
getDateNumAmountTuples defaultDay = 
  map $ getDateNumAmountTuple . (getDateAmountTuple defaultDay)

getDateNumAmountTuple :: (Day, Double) -> (Double, Double)
getDateNumAmountTuple (d,a) = (read (toGnuplotDateString d) :: Double, a)

