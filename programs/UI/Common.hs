module UI.Common
  ( drawPaletteEntry
  , drawPalette
  )
where

import Brick
import Brick.Widgets.Border
import Brick.Widgets.Border.Style
import Lens.Micro.Platform
import qualified Graphics.Vty as V
import qualified Data.Vector as Vec

import Types

drawPaletteEntry :: AppState -> Int -> Int -> Widget Name
drawPaletteEntry s idx width =
    let pal = s^.palette
        entry = Vec.unsafeIndex pal idx
        attr = case entry of
            Nothing -> V.defAttr
            Just c -> V.defAttr `V.withBackColor` c
        ch = ' '
    in raw $ V.string attr (replicate width ch)

drawPalette :: AppState -> Bool -> [Widget Name]
drawPalette s isFgPalette =
    [borderHack, body]
    where
        pal = s^.palette
        Just ext = if isFgPalette
                   then s^.fgPaletteSelectorExtent
                   else s^.bgPaletteSelectorExtent
        mkName = if isFgPalette
                 then FgPaletteEntry
                 else BgPaletteEntry
        borderHack = translateBy l topBorder
        topBorder = hBox [ borderElem bsIntersectL
                         , hLimit 4 hBorder
                         , borderElem bsIntersectB
                         ]
        body = translateBy l $ border $ vBox entries
        l = Location ( fst $ loc $ extentUpperLeft ext
                     , (snd $ extentSize ext) + (snd $ loc $ extentUpperLeft ext) - 1
                     )
        idxs = [0..Vec.length pal-1]
        entries = mkEntry <$> idxs
        mkEntry i = clickable (mkName i) $
                    drawPaletteEntry s i 6
