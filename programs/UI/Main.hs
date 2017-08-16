module UI.Main
  ( drawMainUI
  , toolSelectorEntryWidth
  , boxStyleSelectorEntryWidth
  , styleSelectorEntryWidth
  )
where

import Brick
import Brick.Widgets.Border
import Brick.Widgets.Border.Style
import Brick.Widgets.Center
import Data.Monoid ((<>))
import Data.Maybe (isJust)
import qualified Graphics.Vty as V
import Lens.Micro.Platform

import Types
import UI.Common
import Theme
import Util
import Tart.Canvas

drawMainUI :: AppState -> [Widget Name]
drawMainUI s =
    [ topHud s
    , canvas s
    ]

topHud :: AppState -> Widget Name
topHud s =
    let fgPal = drawPaletteSelector s True
        bgPal = drawPaletteSelector s False
        stySel = drawStyleSelector s
        toolbarEntries = [ drawToolSelector s
                         , toolHud s
                         , vLimit 1 $ fill ' '
                         , fgPal
                         , bgPal
                         , stySel
                         , drawCanvasSize s
                         ]
        filename = case s^.canvasPath of
            Nothing -> "<unsaved>"
            Just p -> p
        modified = if not $ s^.canvasDirty then "" else "*"
    in clickable TopHud $
       vBox [ (padLeft (Pad 1) $ hBox $ padRight (Pad 1) <$> toolbarEntries)
            , hBox [borderElem bsHorizontal <+> str ("[" <> filename <> modified <> "]") <+> hBorder]
            ]

toolHud :: AppState -> Widget Name
toolHud s =
    let toolHuds = [ (Freehand, freehandHud)
                   , (FloodFill, floodfillHud)
                   , (Box, boxHud)
                   , (Eraser, eraserHud)
                   , (Repaint, repaintHud)
                   ]
    in case lookup (s^.tool) toolHuds of
        Nothing -> emptyWidget
        Just f -> f s

freehandHud :: AppState -> Widget Name
freehandHud s = drawChar s

floodfillHud :: AppState -> Widget Name
floodfillHud s = drawChar s

boxStyleSelectorEntryWidth :: Int
boxStyleSelectorEntryWidth = 18

styleSelectorEntryWidth :: Int
styleSelectorEntryWidth = 7

boxHud :: AppState -> Widget Name
boxHud = drawBoxStyleSelector

eraserHud :: AppState -> Widget Name
eraserHud = drawEraserSize

repaintHud :: AppState -> Widget Name
repaintHud = drawRepaintSize

drawEraserSize :: AppState -> Widget Name
drawEraserSize s =
    let inc = clickable IncreaseEraserSize $ withDefAttr keybindingAttr $ str ">>"
        dec = clickable DecreaseEraserSize $ withDefAttr keybindingAttr $ str "<<"
    in borderWithLabel (str "Size") $
       dec <+> (hLimit 5 $ hCenter $ str $ show $ s^.eraserSize) <+> inc

drawRepaintSize :: AppState -> Widget Name
drawRepaintSize s =
    let inc = clickable IncreaseRepaintSize $ withDefAttr keybindingAttr $ str ">>"
        dec = clickable DecreaseRepaintSize $ withDefAttr keybindingAttr $ str "<<"
    in borderWithLabel (str "Size") $
       dec <+> (hLimit 5 $ hCenter $ str $ show $ s^.repaintSize) <+> inc

drawBoxStyleSelector :: AppState -> Widget Name
drawBoxStyleSelector s =
    let styleName = fst $ getBoxBorderStyle s
    in clickable BoxStyleSelector $
       borderWithLabel (str "Box Style") $
       hLimit boxStyleSelectorEntryWidth $
       hCenter $ str styleName

drawStyleSelector :: AppState -> Widget Name
drawStyleSelector s =
    clickable StyleSelector $
    borderWithLabel (str "Style") $
    hLimit styleSelectorEntryWidth $
    hCenter $ raw $ V.string (V.defAttr `V.withStyle` (s^.drawStyle)) "demo"

drawCanvasSize :: AppState -> Widget Name
drawCanvasSize s =
    let (width, height) = canvasSize $ s^.drawing
    in clickable ResizeCanvas $
       borderWithLabel (str "Can" <+> (withDefAttr keybindingAttr (str "v")) <+> str "as") $
       hLimit 8 $ hCenter (str $ show width <> "x" <> show height)

drawChar :: AppState -> Widget Name
drawChar s =
    clickable CharSelector $
    borderWithLabel ((withDefAttr keybindingAttr $ str "C") <+> str "har") $
    padLeftRight 2 $ str [s^.drawCharacter]

toolSelectorEntryWidth :: Int
toolSelectorEntryWidth = 20

drawToolSelector :: AppState -> Widget Name
drawToolSelector s =
    let Just idx = lookup (s^.tool) tools
    in clickable ToolSelector $
       borderWithLabel ((withDefAttr keybindingAttr $ str "T") <+> str "ool") $
       hLimit toolSelectorEntryWidth $
       hCenter $
       (withDefAttr keybindingAttr (str $ show idx)) <+>
       (str $ ":" <> toolName (s^.tool))

drawPaletteSelector :: AppState -> Bool -> Widget Name
drawPaletteSelector s isFg =
    (clickable selName $ borderWithLabel label curColor)
    where
        label = if isFg
                then (withDefAttr keybindingAttr $ str "F") <+> str "G"
                else (withDefAttr keybindingAttr $ str "B") <+> str "G"
        curIdx = if isFg then s^.drawFgPaletteIndex
                         else s^.drawBgPaletteIndex
        selName = if isFg then FgSelector else BgSelector
        curColor = drawPaletteEntry s curIdx 4

canvas :: AppState -> Widget Name
canvas s =
    let cs = if shouldUseOverlay s
             then [ s^.drawingOverlay
                  , s^.drawing
                  ]
             else [ s^.drawing
                  ]
    in centerAbout (s^.canvasOffset & _2 %~ pred) $
       updateAttrMap (applyAttrMappings [(borderAttr, fg V.white)]) $
       border $
       clickable Canvas $
       raw $ canvasToImage cs

shouldUseOverlay :: AppState -> Bool
shouldUseOverlay s =
    isJust $ s^.dragging
