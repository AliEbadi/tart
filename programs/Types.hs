{-# LANGUAGE BinaryLiterals #-}
{-# LANGUAGE TemplateHaskell #-}
module Types
  ( Mode(..)
  , Name(..)
  , Tool(..)
  , AppEvent(..)
  , Action(..)
  , toolName

  , noStyle
  , setStyle
  , clearStyle
  , toggleStyle
  , hasStyle

  , AppState(..)
  , drawing
  , drawingOverlay
  , mode
  , tool
  , drawFgPaletteIndex
  , drawBgPaletteIndex
  , palette
  , drawCharacter
  , fgPaletteSelectorExtent
  , bgPaletteSelectorExtent
  , toolSelectorExtent
  , boxStyleSelectorExtent
  , styleSelectorExtent
  , canvasExtent
  , dragging
  , canvasSizeWidthEdit
  , canvasSizeHeightEdit
  , canvasSizeFocus
  , canvasOffset
  , canvasPath
  , canvasDirty
  , askToSaveFilenameEdit
  , appEventChannel
  , textEntered
  , textEntryStart
  , boxStyleIndex
  , eraserSize
  , repaintSize
  , undoStack
  , redoStack
  , drawStyle
  )
where

import Data.Bits ((.&.), (.|.), complement)
import Data.Word (Word8)
import Brick (Extent, Location)
import Brick.BChan (BChan)
import Brick.Focus
import Brick.Widgets.Edit (Editor)
import qualified Data.Text as T
import Lens.Micro.TH
import qualified Data.Vector as Vec
import qualified Graphics.Vty as V

import Tart.Canvas

data AppEvent =
    DragFinished Name Location Location
    deriving (Eq)

data Action =
    SetPixels [((Int, Int), (Char, V.Attr))]
    | ClearCanvasDirty
    deriving (Eq, Show)

data Mode = Main
          | CharacterSelect
          | FgPaletteEntrySelect
          | BgPaletteEntrySelect
          | ToolSelect
          | StyleSelect
          | BoxStyleSelect
          | CanvasSizePrompt
          | AskToSave
          | TextEntry
          deriving (Eq, Show)

data Name = Canvas
          | TopHud
          | BottomHud
          | ToolSelector
          | ToolSelectorEntry Tool
          | CharSelector
          | FgSelector
          | BgSelector
          | StyleSelector
          | StyleSelectorEntry V.Style
          | FgPaletteEntry Int
          | BgPaletteEntry Int
          | BoxStyleSelectorEntry Int
          | ResizeCanvas
          | CanvasSizeWidthEdit
          | CanvasSizeHeightEdit
          | AskToSaveFilenameEdit
          | TextEntryCursor
          | BoxStyleSelector
          | IncreaseEraserSize
          | DecreaseEraserSize
          | IncreaseRepaintSize
          | DecreaseRepaintSize
          deriving (Eq, Show, Ord)

data Tool = Freehand
          | Box
          | Repaint
          | Eyedropper
          | FloodFill
          | Eraser
          | TextString
          deriving (Eq, Show, Ord)

toolName :: Tool -> String
toolName Freehand   = "Freehand"
toolName Box        = "Box"
toolName Repaint    = "Repaint"
toolName Eraser     = "Eraser"
toolName Eyedropper = "Eyedropper"
toolName FloodFill  = "Flood fill"
toolName TextString = "Text string"

newtype DrawStyle =
    DrawStyle Word8
    deriving (Eq, Show)

setStyle :: V.Style -> V.Style -> V.Style
setStyle a b = a .|. b

toggleStyle :: V.Style -> V.Style -> V.Style
toggleStyle a b =
    if hasStyle a b
    then clearStyle a b
    else setStyle a b

hasStyle :: V.Style -> V.Style -> Bool
hasStyle a b = a .&. b /= 0

clearStyle :: V.Style -> V.Style -> V.Style
clearStyle old dest = dest .&. complement old

noStyle :: V.Style
noStyle = 0

data AppState =
    AppState { _drawing                 :: Canvas
             , _drawingOverlay          :: Canvas
             , _mode                    :: Mode
             , _drawFgPaletteIndex      :: Int
             , _drawBgPaletteIndex      :: Int
             , _drawStyle               :: V.Style
             , _drawCharacter           :: Char
             , _tool                    :: Tool
             , _palette                 :: Vec.Vector (Maybe V.Color)
             , _fgPaletteSelectorExtent :: Maybe (Extent Name)
             , _bgPaletteSelectorExtent :: Maybe (Extent Name)
             , _toolSelectorExtent      :: Maybe (Extent Name)
             , _boxStyleSelectorExtent  :: Maybe (Extent Name)
             , _styleSelectorExtent     :: Maybe (Extent Name)
             , _canvasExtent            :: Maybe (Extent Name)
             , _dragging                :: Maybe (Name, Location, Location)
             , _canvasSizeWidthEdit     :: Editor T.Text Name
             , _canvasSizeHeightEdit    :: Editor T.Text Name
             , _canvasSizeFocus         :: FocusRing Name
             , _canvasOffset            :: Location
             , _canvasPath              :: Maybe FilePath
             , _canvasDirty             :: Bool
             , _askToSaveFilenameEdit   :: Editor T.Text Name
             , _appEventChannel         :: BChan AppEvent
             , _textEntered             :: T.Text
             , _textEntryStart          :: (Int, Int)
             , _boxStyleIndex           :: Int
             , _eraserSize              :: Int
             , _repaintSize             :: Int
             , _undoStack               :: [[Action]]
             , _redoStack               :: [[Action]]
             }

makeLenses ''AppState
