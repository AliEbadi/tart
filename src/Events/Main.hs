module Events.Main
  ( handleMainEvent
  )
where

import Brick
import Data.Char (isDigit)
import qualified Graphics.Vty as V

import Types
import Draw
import Util
import Events.Common

handleMainEvent :: AppState -> BrickEvent Name e -> EventM Name (Next AppState)
handleMainEvent s e = do
    result <- handleCommonEvent s e
    case result of
        Just s' -> continue s'
        Nothing -> handleEvent s e

handleEvent :: AppState -> BrickEvent Name e -> EventM Name (Next AppState)
handleEvent s (VtyEvent (V.EvKey (V.KChar 's') [])) = do
    continue $ beginCanvasSizePrompt s
handleEvent s (MouseDown ResizeCanvas _ _ _) = do
    continue $ beginCanvasSizePrompt s
handleEvent s (VtyEvent (V.EvKey (V.KChar 'f') [])) = do
    continue $ beginFgPaletteSelect s
handleEvent s (MouseDown FgSelector _ _ _) = do
    continue $ beginFgPaletteSelect s
handleEvent s (VtyEvent (V.EvKey (V.KChar 'b') [])) = do
    continue $ beginBgPaletteSelect s
handleEvent s (MouseDown BgSelector _ _ _) = do
    continue $ beginBgPaletteSelect s
handleEvent s (MouseDown ToolSelector _ _ _) = do
    continue $ beginToolSelect s
handleEvent s (MouseDown Canvas _ _ (Location l)) = do
    continue =<< drawWithCurrentTool l s
handleEvent s (VtyEvent (V.EvKey (V.KChar '+') [])) = do
    continue =<< increaseCanvasSize s
handleEvent s (VtyEvent (V.EvKey (V.KChar '-') [])) = do
    continue =<< decreaseCanvasSize s
handleEvent s (VtyEvent (V.EvKey (V.KChar 'q') [])) = halt s
handleEvent s (VtyEvent (V.EvKey (V.KChar c) [])) | isDigit c = do
    let idx = read [c]
    case filter ((== idx) . snd) tools of
        [(t, _)] -> continue $ setMode Main $ setTool s t
        _ -> continue s
handleEvent s (VtyEvent (V.EvKey (V.KChar 'c') [])) =
    continue $ beginCharacterSelect s
handleEvent s (MouseDown CharSelector _ _ _) = do
    continue $ beginCharacterSelect s
handleEvent s _ = continue s
