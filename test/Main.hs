{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NamedFieldPuns #-}

import Common
import Bytea
import Notify

import Control.Exception            (bracket)
import Control.Monad                (when)
import System.Exit                  (exitFailure)
import System.IO

-- | Action for connecting to the database that will be used for testing.
--
-- Note that some tests, such as Notify, use multiple connections, and assume
-- that 'testConnect' connects to the same database every time it is called.
testConnect :: IO Connection
testConnect = connectPostgreSQL ""

withTestEnv :: (TestEnv -> IO a) -> IO a
withTestEnv cb =
    withConn $ \conn ->
        cb TestEnv
            { conn     = conn
            , withConn = withConn
            }
  where
    withConn = bracket testConnect close

tests :: [TestEnv -> Test]
tests =
    [ TestLabel "Bytea"     . testBytea
    , TestLabel "Notify"    . testNotify
    ]

main :: IO ()
main = do
    mapM_ (`hSetBuffering` LineBuffering) [stdout, stderr]
    Counts{cases, tried, errors, failures} <-
        withTestEnv $ \env -> runTestTT $ TestList $ map ($ env) tests
    when (cases /= tried || errors /= 0 || failures /= 0) $ exitFailure
