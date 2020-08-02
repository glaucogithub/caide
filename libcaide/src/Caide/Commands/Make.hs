{-# LANGUAGE CPP, OverloadedStrings #-}
module Caide.Commands.Make(
      updateTests
    , make
) where

#ifndef AMP
import Control.Applicative ((<$>))
#endif
import Control.Monad (forM_)
import Control.Monad.State (liftIO)
import Data.List (sortBy)
import Data.Ord (comparing)

import qualified Data.Text as T

import Prelude hiding (FilePath)
import Filesystem (isDirectory, listDirectory, createTree, removeFile, writeTextFile)
import Filesystem.Path.CurrentOS (FilePath, fromText, encodeString,
    hasExtension, basename, filename, (</>))
import Filesystem.Util (copyFileToDir, pathToText)

import System.Environment (getExecutablePath)

import Caide.Configuration (getActiveProblem, readProblemState)
import Caide.Registry (findLanguage)
import Caide.Types
import Caide.TestCases.Types (ComparisonResult(..), TestState(..),
    readTestReport, writeTests)



withProblem :: Maybe ProblemID -> (ProblemID -> FilePath -> CaideM IO a) -> CaideM IO a
withProblem mbProbId processProblem = do
    probId <- case mbProbId of
        Just probId' -> return probId'
        Nothing -> getActiveProblem
    root <- caideRoot
    let problemDir = root </> fromText probId
    problemExists <- liftIO $ isDirectory problemDir
    if problemExists
    then processProblem probId problemDir
    else throw . T.concat $ ["Problem ", probId, " doesn't exist"]

make :: Maybe ProblemID -> CaideIO ()
make p = withProblem p $ \probId _ -> makeProblem probId

updateTests :: Maybe ProblemID -> CaideIO ()
updateTests mbProbId = withProblem mbProbId $ \_ problemDir -> liftIO $ do
    caideExe <- getExecutablePath
    copyTestInputs problemDir
    updateTestList problemDir
    let testDir = problemDir </> ".caideproblem" </> "test"
    writeTextFile (testDir </> "caideExe.txt") $ T.pack caideExe

prepareSubmission :: ProblemID -> CaideIO ()
prepareSubmission probId = do
    hProblem <- readProblemState probId
    lang <- getProp hProblem "problem" "language"
    case findLanguage lang of
        Nothing            -> throw . T.concat $ ["Unsupported programming language ", lang]
        Just (_, language) -> inlineCode language probId

makeProblem :: ProblemID -> CaideIO ()
makeProblem probId = updateTests (Just probId) >> prepareSubmission probId

copyTestInputs :: FilePath -> IO ()
copyTestInputs problemDir = do
    let tempTestDir = problemDir </> ".caideproblem" </> "test"
    createTree tempTestDir

    -- Cleanup output from previous test run
    let filesToKeep = ["testList.txt", "report.txt", "caideExe.txt"]
    filesToClear <- filter ((`notElem` filesToKeep) . encodeString . filename) <$> listDirectory tempTestDir
    forM_ filesToClear removeFile

    fileList <- listDirectory problemDir
    -- Copy input files
    -- TODO: don't
    let testInputs = filter (`hasExtension` "in") fileList
    forM_ testInputs $ \inFile -> copyFileToDir inFile tempTestDir


-- | Updates testList.txt file:
--    * removes missing tests
--    * adds new tests
--    * makes sure previously failed tests (if any) come first
updateTestList :: FilePath -> IO ()
updateTestList problemDir = do
    let testDir = problemDir </> ".caideproblem" </> "test"
        previousRunFile = testDir </> "report.txt"
    report <- readTestReport previousRunFile
    allFiles <- listDirectory problemDir
    let allTests    = map (pathToText . basename) . filter (`hasExtension` "in") $ allFiles
        testsToSkip = map (pathToText . basename) . filter (`hasExtension` "skip") $ allFiles
        testState testName = if testName `elem` testsToSkip then Skip else Run
        testList = zip allTests (map testState allTests)
        succeededAndName (testName, _) = case lookup testName report of
            Just (Failed _) -> (False, testName)
            Just (Error _)  -> (False, testName)
            _               -> (True,  testName)
        sortedTests = sortBy (comparing succeededAndName) testList
        testListFile = testDir </> "testList.txt"
    writeTests sortedTests testListFile

