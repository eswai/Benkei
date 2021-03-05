//
//  Naginata.m
//  Benkei
//
//  Created by eswai on 2021/02/07.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#import <Foundation/Foundation.h>
#import "Naginata.h"
#import "NGKey.h"
#import <Carbon/Carbon.h>


NSFileHandle *debugOutFile1 = nil;
#define debugOut(...) \
 [((debugOutFile1 == nil) ? (debugOutFile1 = [NSFileHandle fileHandleWithStandardOutput]) : debugOutFile1) \
  writeData:[[NSString stringWithFormat:__VA_ARGS__] dataUsingEncoding:NSUTF8StringEncoding]]

@implementation Naginata

NSMutableArray *ngbuf; // 未変換のキーバッファ
NSDictionary *ng_keymap; // かな変換テーブル
NSArray *shiftkeys; // 薙刀式で連続シフトキーになるキー（濁点、半濁点、小書、編集モードも含む）
NSMutableSet *pressed; // 押されているキー
NSMutableDictionary *ngdic; // CGKeycodeからNGKeyへの辞書。同時にここに入っているキーが一連の変換に使ったキーの集合を表す。

- (instancetype)init
{
    self = [super init];
    if (self) {
        ngbuf = [NSMutableArray new];
        pressed = [NSMutableSet new];
        ngdic = [NSMutableDictionary new];
        shiftkeys = @[[NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], nil],
                      [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil],
                      [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil],
                      [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil],
                      [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil],
                      [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], nil],
                      [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], nil],
                      [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], nil],
                      [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], nil],
                      [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], nil],
                      ];
        self.kouchiShift = false;
        self.doujiTime = 0;

        // かな定義　将来的に設定ファイルへ外出しする。
        ng_keymap = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_JIS_Eisu], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_G], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_JIS_Kana], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_J], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Y], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_T], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_Y], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Space], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Delete], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_U], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Return], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_M], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Return], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_Space], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Comma], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_Space], nil],
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_Return], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_Space], nil],

            // 清音
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], nil], // あ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], nil], // い
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_L], nil], // う
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_O], nil], // え
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_N], nil], // お
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], nil], // か
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], nil], // き
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], nil], // く
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], nil], // け
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], nil], // こ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_U], nil], // さ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], nil], // し
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_O], nil], // す
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_A], nil], // せ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], nil], // そ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], nil], // た
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_G], nil], // ち
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_Semicolon], nil], // つ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_E], nil], // て
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], nil], // と
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], nil], // な
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_D], nil], // に
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_S], nil], // ぬ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_W], nil], // ね
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_J], nil], // の
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_C], nil], // は
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], nil], // ひ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_X], nil], // ひ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_Period], nil], // ふ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], nil], // へ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], nil], // ほ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_Z], nil], // ほ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_F], nil], // ま
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_B], nil], // み
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // む
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_R], nil], // め
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_K], nil], // も
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_H], nil], // や
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ゆ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_I], nil], // よ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Period], nil], // ら
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_E], nil], // り
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_I], nil], // る
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Slash], nil], // れ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_Slash], nil], // れ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_A], nil], // ろ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_L], nil], // わ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_ANSI_C], nil], // を
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_N], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // ん
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Minus], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Semicolon], nil], // ー

              // 濁音
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_F], nil], // が
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_Space], nil], // が(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_W], nil], // ぎ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_Space], nil], // ぎ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], nil], // ぐ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // ぐ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_S], nil], // げ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_Space], nil], // げ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ご
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_Space], nil], // ご(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_U], nil], // ざ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_Space], nil], // ざ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], nil], // じ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_Space], nil], // じ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_O], nil], // ず
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // ず(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_A], nil], // ぜ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_A], [NSNumber numberWithInt:kVK_Space], nil], // ぜ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_B], nil], // ぞ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_Space], nil], // ぞ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_N], nil], // だ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Space], nil], // だ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], nil], // ぢ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_Space], nil], // ぢ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_Semicolon], nil], // づ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_Space], nil], // づ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_E], nil], // で
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_Space], nil], // で(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_D], nil], // ど
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_Space], nil], // ど(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_C], nil], // ば
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_Space], nil], // ば(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_X], nil], // び
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_Space], nil], // び(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_Period], nil], // ぶ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_Space], nil], // ぶ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_P], nil], // べ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // べ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_Z], nil], // ぼ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_Space], nil], // ぼ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], nil], // ゔ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_Space], nil], // ゔ(冗長)

              // 半濁音
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_C], nil], // ぱ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_Space], nil], // ぱ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_X], nil], // ぴ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_Space], nil], // ぴ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], nil], // ぷ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_Space], nil], // ぷ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ぺ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // ぺ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Z], nil], // ぽ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_Space], nil], // ぽ(冗長)

              // 小書き
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_H], nil], // ゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // ゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // ゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_I], nil], // ょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // ょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_J], nil], // ぁ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_Space], nil], // ぁ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_Space], nil], // ぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_L], nil], // ぅ
//            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_Space], nil], // ぅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_O], nil], // ぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // ぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_N], nil], // ぉ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Space], nil], // ぉ
//            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_L], nil], // ゎ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_Space], nil], // ゎ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], nil], // っ

              // 清音拗音 濁音拗音 半濁拗音
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_H], nil], // しゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // しゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_P], nil], // しゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // しゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_I], nil], // しょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // しょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_H], nil], // じゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // じゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_P], nil], // じゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // じゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_I], nil], // じょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // じょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_H], nil], // きゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // きゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_P], nil], // きゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // きゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_I], nil], // きょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // きょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_H], nil], // ぎゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // ぎゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ぎゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // ぎゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_I], nil], // ぎょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // ぎょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_H], nil], // ちゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // ちゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ちゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // ちゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_I], nil], // ちょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // ちょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_H], nil], // ぢゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // ぢゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ぢゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // ぢゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_I], nil], // ぢょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // ぢょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_H], nil], // にゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // にゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_P], nil], // にゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // にゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_I], nil], // にょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // にょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_H], nil], // ひゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // ひゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ひゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // ひゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], // ひょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // ひょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_H], nil], // びゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // びゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_P], nil], // びゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // びゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], // びょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // びょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_H], nil], // ぴゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // ぴゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ぴゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // ぴゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], // ぴょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // ぴょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_H], nil], // みゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // みゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_P], nil], // みゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // みゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_I], nil], // みょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // みょ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_H], nil], // りゃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_Space], nil], // りゃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_P], nil], // りゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // りゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_I], nil], // りょ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_Space], nil], // りょ(冗長)

              // 清音外来音 濁音外来音
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_K], nil], // てぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_Space], nil], // てぃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_P], nil], // てゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // てゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_K], nil], // でぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_Space], nil], // でぃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_P], nil], // でゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // でゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_L], nil], // とぅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_Space], nil], // とぅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_L], nil], // どぅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_Space], nil], // どぅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_O], nil], // しぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // しぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_O], nil], // ちぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // ちぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_O], nil], // じぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // じぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_O], nil], // ぢぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // ぢぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_J], nil], // ふぁ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_Space], nil], // ふぁ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ふぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_Space], nil], // ふぃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_O], nil], // ふぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // ふぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_N], nil], // ふぉ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Space], nil], // ふぉ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ふゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // ふゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_O], nil], // いぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // いぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_K], nil], // うぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_Space], nil], // うぃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_O], nil], // うぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // うぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_N], nil], // うぉ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Space], nil], // うぉ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_J], nil], // ゔぁ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_Space], nil], // ゔぁ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ゔぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_Space], nil], // ゔぃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_O], nil], // ゔぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // ゔぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_N], nil], // ゔぉ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Space], nil], // ゔぉ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_P], nil], // ゔゅ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_U], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Space], nil], // ゔゅ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_J], nil], // くぁ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_Space], nil], // くぁ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_K], nil], // くぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_Space], nil], // くぃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_O], nil], // くぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // くぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_N], nil], // くぉ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Space], nil], // くぉ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_L], nil], // くゎ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_Space], nil], // くゎ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_J], nil], // ぐぁ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_Space], nil], // ぐぁ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ぐぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_Space], nil], // ぐぃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_O], nil], // ぐぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // ぐぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_N], nil], // ぐぉ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Space], nil], // ぐぉ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_L], nil], // ぐゎ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_Space], nil], // ぐゎ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_J], nil], // つぁ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_Space], nil], // つぁ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_K], nil], // つぃ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_Space], nil], // つぃ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_O], nil], // つぇ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_Space], nil], // つぇ(冗長)
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_N], nil], // つぉ
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_O], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Space], nil], // つぉ(冗長)

                     
            // 編集モード1
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Command], [NSNumber numberWithInt:kVK_LeftArrow], [NSNumber numberWithInt:kVK_Command], [NSNumber numberWithInt:kVK_DownArrow], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ^{End}
            [NSArray arrayWithObjects: @"｜", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ｜{改行}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Command], [NSNumber numberWithInt:kVK_ANSI_S], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ^s
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_Slash], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ・
            [NSArray arrayWithObjects: @"……", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_A], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ……{改行}
            [NSArray arrayWithObjects: @"《", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // 《{改行}
            [NSArray arrayWithObjects: @"？", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ？{改行}
            [NSArray arrayWithObjects: @"「", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // 「{改行}
            [NSArray arrayWithObjects: @"(", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ({改行}
            [NSArray arrayWithObjects: @"││", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ││{改行}
            [NSArray arrayWithObjects: @"》", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // 》{改行}
            [NSArray arrayWithObjects: @"！", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ！{改行}
            [NSArray arrayWithObjects: @"」", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // 」{改行}
            [NSArray arrayWithObjects: @")", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_K], nil], // ){改行}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {Home}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_K], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // +{End}{BS}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_JIS_Kana], [NSNumber numberWithInt:kVK_JIS_Kana], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {vk1Csc079}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Delete], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {Del}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Escape], [NSNumber numberWithInt:kVK_Escape], [NSNumber numberWithInt:kVK_Escape], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {Esc 3}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Return], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {Enter}{End}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_B], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {↑}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_B], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // +{↑}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_B], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {↑ 5}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_K], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // ^i
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {End}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_F], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {↓}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_F], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Comma], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // +{↓}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_F], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // {↓ 5}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_J], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Slash], [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_F], nil], // ^u
            // 編集モード2
            [NSArray arrayWithObjects: @"／", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // ／{改行}
            [NSArray arrayWithObjects: @"｜", [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_E], @"《》", [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_B], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_W], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // ｜{改行}{End}《》{改行}{↑}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_A], [NSNumber numberWithInt:kVK_Return], [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_E], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // {Home}{改行}{Space 3}{End}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_A], [NSNumber numberWithInt:kVK_Return], [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_R], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // {Home}{改行}{Space 1}{End}
            [NSArray arrayWithObjects: @"〇", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 〇{改行}
            [NSArray arrayWithObjects: @"【", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_A], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 【{改行}
            [NSArray arrayWithObjects: @"〈", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 〈{改行}
            [NSArray arrayWithObjects: @"『", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_D], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 『{改行}
            [NSArray arrayWithObjects: @"」", [NSNumber numberWithInt:kVK_Return], @"「", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_F], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 」{改行 2}「{改行}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_Space], [NSNumber numberWithInt:kVK_Space], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_G], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // {Space 3}
            [NSArray arrayWithObjects: @"】", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Z], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 】{改行}
            [NSArray arrayWithObjects: @"〉", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 〉{改行}
            [NSArray arrayWithObjects: @"』", nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 』{改行}
            [NSArray arrayWithObjects: @"」", [NSNumber numberWithInt:kVK_Return], [NSNumber numberWithInt:kVK_Space], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_V], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 」{改行 2}{Space}
            [NSArray arrayWithObjects: @"　　　×　　　×　　　×", [NSNumber numberWithInt:kVK_Return], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_B], [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_Comma], nil], // 　　　×　　　×　　　×{改行 2}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_A], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Y], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // +{Home}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Command], [NSNumber numberWithInt:kVK_ANSI_X], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_U], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ^x
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Command], [NSNumber numberWithInt:kVK_ANSI_V], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_I], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ^v
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Command], [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_ANSI_Z], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_O], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ^y
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Command], [NSNumber numberWithInt:kVK_ANSI_Z], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ^z
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Command], [NSNumber numberWithInt:kVK_ANSI_C], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_H], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ^c
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_J], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // {→ 5}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_P], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // +{→ 5}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageUp], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_L], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ^{PgUp}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageUp], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageUp], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageUp], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageUp], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageUp], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Semicolon], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ^{PgUp 5}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // +{End}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_M], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // {← 5}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], [NSNumber numberWithInt:kVK_Shift], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_ANSI_N], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Comma], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // +{← 5}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageDown], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Period], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ^{PgDn}
            [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageDown], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageDown], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageDown], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageDown], [NSNumber numberWithInt:kVK_Control], [NSNumber numberWithInt:kVK_PageDown], nil], [NSSet setWithObjects: [NSNumber numberWithInt:kVK_ANSI_Slash], [NSNumber numberWithInt:kVK_ANSI_C], [NSNumber numberWithInt:kVK_ANSI_V], nil], // ^{PgDn 5}

        nil];
    }
    return self;
}

-(NSArray *)pressKey:(CGKeyCode)keycode
{
    debugOut(@"[PRESS] received ngbuf=%@ keycode=%d\n", ngbuf, keycode);
    NSNumber *k = [NSNumber numberWithInt:keycode];
    
    // ガード。今押しているはずのキーの場合は中断
    if ([pressed containsObject:k]) {
        return NULL;
    }
    
    NSArray *kana;
    // シフトキーが来たら、そこで一旦変換してしまう(前置シフト)
    if (keycode == kVK_Space) {
        if ([ngbuf count] > 0) {
            NGKey *ngk = [ngbuf objectAtIndex:0];
            if (!self.kouchiShift || -[ngk.pressTime timeIntervalSinceNow] > self.doujiTime) {
                kana = type();
                [pressed removeAllObjects];
            }
        }
    }
    NGKey *ngk = [[NGKey alloc] initWithKeycode: keycode];
    [ngbuf addObject: ngk];
    [pressed addObject:k];
    [ngdic setObject:ngk forKey:k];

    return kana;
}

-(NSArray *)releaseKey:(CGKeyCode)keycode
{
    debugOut(@"[RELEASE] received ngbuf=%@ keycode=%d\n", ngbuf, keycode);
    NSNumber *k = [NSNumber numberWithInt:keycode];
    NGKey *ngk = [ngdic objectForKey:k];
    ngk.releaseTime = [NSDate new];
    
    // ガード。押してないキーなら中断。
    if (![pressed containsObject:k]) {
        return [NSArray new];
    }
    
    [pressed removeObject:k];
    
    NSArray *kana;
    if ([ngbuf count] > 0) {
        kana = type();
    }
    // 押してるキーがなくなったら辞書を空にする
    if ([pressed count] == 0) {
        [ngdic removeAllObjects];
    }
    
    return kana;
}

-(void)clear
{
    [ngbuf removeAllObjects];
    [ngdic removeAllObjects];
}

// 変換処理
// ngbufのキー組み合わせを辞書から検索して、なかったら、最後の１文字を削って、再度検索を繰り返す。
NSArray *type()
{
    NSUInteger nt = [ngbuf count];
    while (nt > 0) {
        NSArray *r = lookup(nt, true); // 連続シフト有効
        if ([r count] > 0) return r;
        r = lookup(nt, false); // 連続シフト無効で検索しなおす
        if ([r count] > 0) return r;
        nt--;
    }
    NGKey *ngk = [ngbuf objectAtIndex:0];
    [ngbuf removeObjectAtIndex:0];
    return [[NSArray alloc] initWithObjects: [NSNumber numberWithInt:ngk.keycode], nil];
}

// ngbufの先頭からnt文字目までが変換対象
NSArray *lookup(NSUInteger nt, bool shifted)
{
    NSMutableSet *keycomb_buf = [NSMutableSet new];
    // 先頭からnt文字のキー集合を作る
    for (int i = 0; i < nt; i++) {
        NGKey *ngk = [ngbuf objectAtIndex:i];
        [keycomb_buf addObject:[NSNumber numberWithInt:ngk.keycode]];
    }

    // 最初のキー
    NGKey *fk = [ngbuf objectAtIndex:0];

    if (shifted) { // 連続シフトする場合
        // すでに変換してngbufにはないキー。ここから連続シフトするシフトキーをもう一度探す。
        NSMutableSet *ndset =[[NSMutableSet alloc] initWithArray:[ngdic allKeys]];
        for (NGKey *ngk in ngbuf) {
            [ndset removeObject:[NSNumber numberWithInt:ngk.keycode]];
        }
        for (NSSet *s in shiftkeys) {
            if ([s isSubsetOfSet:ndset]) {
                for (NSNumber *k in s) {
                    NGKey *sft = [ngdic objectForKey:k];
                    // シフトキーが変換するキーのプレスにかかっていたら
                    if (sft.releaseTime == NULL || [sft.releaseTime timeIntervalSinceDate:fk.pressTime] >= 0) {
                        [keycomb_buf addObject:k];
                    }
                }
                break;
            }
        }
    }
    
    NSArray *kana = [ng_keymap objectForKey:keycomb_buf];
    if (kana != nil) {
        for (int i = 0; i < nt; i++) {
            [ngbuf removeObjectAtIndex:0];
        }
        return kana;
    } else {
        return [NSArray new];
    }
}

@end
