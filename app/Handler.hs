module Handler
  ( UIEvent(..)
  , eventHandler
  ) where

import           Brick
import qualified Graphics.Vty as V

import           Application
import           Cursor
import           State
import           Style

eventHandler :: State -> BrickEvent UIResource UIEvent -> EventM UIResource (Next State)
eventHandler s (VtyEvent (V.EvKey V.KBS []))            = continue $ modifyText delete $ handleUndo s
eventHandler s (VtyEvent (V.EvKey V.KEnter []))         = continue $ modifyText insertLine $ handleUndo s
eventHandler s (VtyEvent (V.EvKey (V.KChar c) []))      = continue $ modifyText (handleChar c) $ handleUndo s
eventHandler s (VtyEvent (V.EvKey V.KUp []))            = continue $ modifyText moveUp s
eventHandler s (VtyEvent (V.EvKey V.KDown []))          = continue $ modifyText moveDown s
eventHandler s (VtyEvent (V.EvKey V.KLeft []))          = continue $ modifyText moveLeft s
eventHandler s (VtyEvent (V.EvKey V.KLeft [V.MShift]))  = continue $ modifyText selectLeft s
eventHandler s (VtyEvent (V.EvKey V.KRight []))         = continue $ modifyText moveRight s
eventHandler s (VtyEvent (V.EvKey V.KRight [V.MShift])) = continue $ modifyText selectRight s
eventHandler s (VtyEvent (V.EvKey (V.KChar 'z') [V.MCtrl])) = continue $ undo s
eventHandler s (VtyEvent (V.EvKey (V.KChar 'x') [V.MCtrl])) = continue $ redo s
eventHandler s (VtyEvent (V.EvKey V.KEsc []))           = halt s
eventHandler s (VtyEvent (V.EvResize rows cols))        = continue $ resize s rows cols
eventHandler s (VtyEvent (V.EvKey V.KDown [V.MShift]))  = vScrollBy (viewportScroll EditorViewpoint) 1 >> continue s
eventHandler s (VtyEvent (V.EvKey V.KUp   [V.MShift]))  = vScrollBy (viewportScroll EditorViewpoint) (-1) >> continue s
eventHandler s _                                        = continue s

modifyText :: (Cursor StyleChar -> Cursor StyleChar) -> State -> State
modifyText f s = s {text = mapUnselected (\sc -> sc {style = Nothing})
                           $ mapSelected (\sc -> sc {style = Just tiltOn})
                           $ f $ text s}

handleChar :: Char -> Cursor StyleChar -> Cursor StyleChar
handleChar ch c = insert (StyleChar ch Nothing) c

resize :: State -> Int -> Int -> State
resize s rows cols = s {terminalSize = (rows, cols)}

handleUndo :: State -> State
handleUndo s = s {undoText = t:us, redoText = []} where
  t = text s
  us = undoText s
