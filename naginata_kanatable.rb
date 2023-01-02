tanda = <<ETANDA
ヴ|き|て|し|{←}|{→}|{BS}|る|す|へ|@|[  |
ろ|け|と|か|っ  |く  |あ  |い|う|ー|:|]  |
ほ|ひ|は|こ|そ  |た  |な  |ん|ら|れ|\|
ETANDA

shifted = <<ESHIFTED
ヴ|ぬ|り |ね       |+{←}|+{→}|さ       |よ|え|ゆ|`|{{}|
せ|め|に |ま       |ち   |や   |の       |も|つ|ふ|*|{}}|
ほ|ひ|を |、{Enter}|み   |お   |。{Enter}|む|わ|れ|_|
ESHIFTED

eiji    = %w(Q W E R T  Y U I O P  A S D F G  H J K L Semicolon  Z X C V B  N M Comma Period Slash)
eiji_r  = %w(Y U I O P  H J K L Semicolon N M Comma Period Slash)
eiji_l  = %w(Q W E R T  A S D F G  Z X C V B)

tanda = tanda.split("|").map{|c| c.strip}
tanda.delete_at(35)
tanda.delete_at(34)
tanda.delete_at(23)
tanda.delete_at(22)
tanda.delete_at(11)
tanda.delete_at(10)

shifted = shifted.split("|").map{|c| c.strip}
shifted.delete_at(35)
shifted.delete_at(34)
shifted.delete_at(23)
shifted.delete_at(22)
shifted.delete_at(11)
shifted.delete_at(10)

kana      = %w(あ い う え お か き く け こ さ し す せ そ た ち つ て と な に ぬ ね の は ひ ふ へ ほ ま み む め も や ゆ よ ら り る れ ろ わ を ん ー)
r_kana    = %w(a i u e o ka ki ku ke ko sa si su se so ta ti tu te to na ni nu ne no ha hi hu he ho ma mi mu me mo ya yu yo ra ri ru re ro wa wo nn -)

daku      = %w(が ぎ ぐ げ ご ざ じ ず ぜ ぞ だ ぢ づ で ど ば び ぶ べ ぼ ゔ)
r_daku    = %w(ga gi gu ge go za zi zu ze zo da di du de do ba bi bu be bo vu)
t_daku    = %w(か き く け こ さ し す せ そ た ち つ て と は ひ ふ へ ほ う)

handaku   = %w(ぱ ぴ ぷ ぺ ぽ)
t_handaku = %w(は ひ ふ へ ほ)
r_handaku = %w(pa pi pu pe po)

kogaki    = %w(ゃ ゅ ょ ぁ ぃ ぅ ぇ ぉ ゎ っ)
t_kogaki  = %w(や ゆ よ あ い う え お わ っ)
r_kogaki  = %w(xya xyu xyo xa xi xu xe xo xwa xtu)

kumiawase = []
r_kumiawase = []
kumiawase << %w(しゃ しゅ しょ じゃ じゅ じょ)
r_kumiawase << %w(sya syu syo zya zyu zyo)
kumiawase << %w(きゃ きゅ きょ ぎゃ ぎゅ ぎょ)
r_kumiawase << %w(kya kyu kyo gya gyu gyo)
kumiawase << %w(ちゃ ちゅ ちょ ぢゃ ぢゅ ぢょ)
r_kumiawase << %w(tya tyu tyo dya dyu dyo)
kumiawase << %w(にゃ にゅ にょ)
r_kumiawase << %w(nya nyu nyo)
kumiawase << %w(ひゃ ひゅ ひょ びゃ びゅ びょ ぴゃ ぴゅ ぴょ)
r_kumiawase << %w(hya hyu hyo bya byu byo pya pyu pyo)
kumiawase << %w(みゃ みゅ みょ)
r_kumiawase << %w(mya myu myo)
kumiawase << %w(りゃ りゅ りょ)
r_kumiawase << %w(rya ryu ryo)

gairai = []
r_gairai = []
gairai << %w(てぃ てゅ でぃ でゅ)
r_gairai << %w(thi thu dhi dhu)
gairai << %w(とぅ どぅ)
r_gairai << %w(toxu doxu)
gairai << %w(しぇ ちぇ じぇ ぢぇ)
r_gairai << %w(sye tye zye dye)

gairai << %w(ふぁ ふぃ ふぇ ふぉ ふゅ)
r_gairai << %w(fa fi fe fo fyu)
gairai << %w(いぇ)
r_gairai << %w(ixe)
gairai << %w(うぃ うぇ うぉ ゔぁ ゔぃ ゔぇ ゔぉ ゔゅ)
r_gairai << %w(wi we uxo va vi ve vo vuxyu)
gairai << %w(くぁ くぃ くぇ くぉ くゎ ぐぁ ぐぃ ぐぇ ぐぉ ぐゎ)
r_gairai << %w(kuxa kuxi kuxe kuxo kuxwa guxa guxi guxe guxo guxwa)
gairai << %w(つぁ)
r_gairai << %w(tsa)

kumiawase.flatten!
r_kumiawase.flatten!
gairai.flatten!
r_gairai.flatten!

def teigi(a, b, c, prefix="", suffix="")
  as = [a].flatten.map{|k| "[NSNumber numberWithInt:kVK_ANSI_#{k}]"}
  as.unshift "[NSNumber numberWithInt:#{prefix}]" if prefix != ""
  as.push "[NSNumber numberWithInt:#{suffix}]" if suffix != ""
  as = as.join(", ")

  _b = []
  [b].flatten.join("").each_char {|x| _b << x }
  bs = _b.map{|k| "[NSNumber numberWithInt:kVK_ANSI_#{k.upcase}]"}.join(", ")

  sprintf("[NSArray arrayWithObjects: #{bs}, nil], [NSSet setWithObjects: #{as}, nil], // #{c}")
end

puts "  // 清音"
kana.each_with_index do |k, i|
  j = tanda.index(k)
  if j && j >= 0
    puts teigi(eiji[j], r_kana[i], k)
  end
  j = shifted.index(k)
  if j && j >= 0
    puts teigi(eiji[j], r_kana[i], k, "kVK_Space")
    puts teigi(eiji[j], r_kana[i], k, "kVK_Return")
  end
end

puts
puts "  // 濁音"
daku.each_with_index do |k, i|
  j = tanda.index(t_daku[i]) || shifted.index(t_daku[i])
  if j && j >= 0
    if eiji_r.index(eiji[j])
      puts teigi(eiji[j], r_daku[i], k, "kVK_ANSI_F")
      # puts teigi(eiji[j], r_daku[i], k + "(冗長)", "kVK_ANSI_F", "kVK_Space")
    else
      puts teigi(eiji[j], r_daku[i], k, "kVK_ANSI_J")
      # puts teigi(eiji[j], r_daku[i], k + "(冗長)", "kVK_ANSI_J", "kVK_Space")
    end
  end
end

puts
puts "  // 半濁音"
handaku.each_with_index do |k, i|
  j = tanda.index(t_handaku[i]) || shifted.index(t_handaku[i])
  if j && j >= 0
    if eiji_r.index(eiji[j])
      puts teigi(eiji[j], r_handaku[i], k, "kVK_ANSI_V")
      # puts teigi(eiji[j], r_handaku[i], k + "(冗長)", "kVK_ANSI_V", "kVK_Space")
    else
      puts teigi(eiji[j], r_handaku[i], k, "kVK_ANSI_M")
      # puts teigi(eiji[j], r_handaku[i], k + "(冗長)", "kVK_ANSI_M", "kVK_Space")
    end
  end
end

puts
puts "  // 小書き"
kogaki.each_with_index do |k, i|
  j = tanda.index(k)
  if j && j >= 0
    puts teigi(eiji[j], r_kogaki[i], k)
    next
  end
  j = shifted.index(k)
  if j && j >= 0
    puts teigi(eiji[j], r_kogaki[i], k, "kVK_Space")
    puts teigi(eiji[j], r_kogaki[i], k, "kVK_Return")
    next
  end

  j = tanda.index(t_kogaki[i]) || shifted.index(t_kogaki[i])
  if j && j >= 0
    puts teigi(eiji[j], r_kogaki[i], k, "kVK_ANSI_Q")
    # puts teigi(eiji[j], r_kogaki[i], k, "kVK_ANSI_Q", "kVK_Space")
    # puts teigi(eiji[j], r_kogaki[i], k, "B_V|B_M|")
    # puts teigi(eiji[j], r_kogaki[i], k + "(冗長)", "B_V|B_M|", "|B_SHFT")
  end
end

puts
puts "  // 清音拗音 濁音拗音 半濁拗音"
kumiawase.each_with_index do |k, i|
  j = tanda.index(k[0])
  if j && j >= 0
    e0 = eiji[j]
  end
  unless e0
    j = shifted.index(k[0])
    if j && j >= 0
      e0 = eiji[j]
    end
  end
  unless e0
    l = daku.index(k[0])
    if l && l >= 0
      j = tanda.index(t_daku[l]) || shifted.index(t_daku[l])
      if j && j >= 0
        if eiji_r.index(eiji[j])
          e0 = ["F", eiji[j]]
        else
          e0 = ["J", eiji[j]]
        end
      end
    end
  end
  unless e0
    l = handaku.index(k[0])
    if l && l >= 0
      j = tanda.index(t_handaku[l]) || shifted.index(t_handaku[l])
      if j && j >= 0
        if eiji_r.index(eiji[j])
          e0 = ["V", eiji[j]]
        else
          e0 = ["M", eiji[j]]
        end
      end
    end
  end

  l = kogaki.index(k[1])
  j = tanda.index(t_kogaki[l]) || shifted.index(t_kogaki[l])
  if j && j >= 0
    e1 = eiji[j]
    puts teigi([e0, e1], r_kumiawase[i], k)
    # puts teigi([e0, e1], r_kumiawase[i], k + "(冗長)", "", "kVK_Space")
  end
end

puts
puts "  // 清音外来音 濁音外来音"
gairai.each_with_index do |k, i|
  j = tanda.index(k[0]) || shifted.index(k[0])
  if j && j >= 0
    if eiji_r.index(eiji[j])
      e0 = ["V", eiji[j]]
    else
      e0 = ["M", eiji[j]]
    end
  end
  unless e0
    l = daku.index(k[0])
    if l && l >= 0
      j = tanda.index(t_daku[l]) || shifted.index(t_daku[l])
      if j && j >= 0
        if eiji_r.index(eiji[j])
          e0 = ["F", eiji[j]]
        else
          e0 = ["J", eiji[j]]
        end
      end
    end
  end

  l = kogaki.index(k[1])
  j = tanda.index(t_kogaki[l]) || shifted.index(t_kogaki[l])
  if j && j >= 0
    e1 = eiji[j]
    puts teigi([e0, e1], r_gairai[i], k)
    # puts teigi([e0, e1], r_gairai[i], k + "(冗長)", "", "kVK_Space")
  end
end




# 編集モード

mode1l = <<MEND
^{End}    |《》{改行}{↑}|/*ディ*/|^s            |・            ||||||||
……{改行}|(){改行}{↑}  |？{改行}|「」{改行}{↑}|『』{改行}{↑}||||||||
││{改行}|【】{改行}{↑}|！{改行}|{改行}{↓}    |／{改行}      |||||||
MEND

mode1r = <<MEND
|||||{Home}      |+{End}{BS}|{vk1Csc079}|{Del}  |{Esc 3}|  |  |
|||||{Enter}{End}|{↑}      |+{↑}      |+{↑ 7}|^i     |  |  |
|||||{End}       |{↓}      |+{↓}      |+{↓ 7}|^u     |  |
MEND

mode2l = <<MEND
{Home}{Del 3}{BS}{←}           |^x｜{改行}^v《》{改行}{↑}  |{Home}{改行}{Space 3}{←}|{Space 3}                      |〇{改行}      ||||||||
{Home}{Del 1}{BS}{←}           |^x(^v){改行}{Space}+{↑}^x  |{Home}{改行}{Space 1}{←}|^x「^v」{改行}{Space}+{↑}^x   |^x『^v』{改行}{Space}+{↑}^x||||||||
　　　×　　　×　　　×{改行 2}|^x【^v】{改行}{Space}+{↑}^x|{改行}{End}{改行}}       |{改行}{End}{改行}「」{改行}{↑}|{End}{改行}   |||||||
MEND

mode2r = <<MEND
|||||+{Home}|^x    |^z   |^y      |^v      |  |  |
|||||^c     |{→ 5}|+{→}|+{→ 5} |+{→ 20}|  |  |
|||||+{End} |{← 5}|+{←}|+{← 5} |+{← 20}|  |
MEND

$henshu = {
"？{改行}"       => ["？"],
"！{改行}"       => ["！"],
"{Home}"        => ["kVK_Control", "kVK_ANSI_A"],
"{End}"         => ["kVK_Control", "kVK_ANSI_E"],
"+{Home}"       => ["kVK_Shift", "kVK_Control", "kVK_ANSI_A"],
"+{End}"        => ["kVK_Shift", "kVK_Control", "kVK_ANSI_E"],
"^{End}"        => ["kVK_Command", "kVK_LeftArrow", "kVK_Command", "kVK_DownArrow"],
"+{End}{BS}"    => ["kVK_Control", "kVK_ANSI_K"], # 末消
"{vk1Csc079}"   => ["kVK_JIS_Kana", "kVK_JIS_Kana"], # 再変換
"{Del}"         => ["kVK_Delete"],
"{Esc 3}"       => ["kVK_Escape", "kVK_Escape", "kVK_Escape"],
"{↑}"           => ["kVK_Control", "kVK_ANSI_B"],
"{↓}"           => ["kVK_Control", "kVK_ANSI_F"],
"+{↑}"          => ["kVK_Shift", "kVK_Control", "kVK_ANSI_B"],
"+{↓}"          => ["kVK_Shift", "kVK_Control", "kVK_ANSI_F"],
"{↑ 5}"         => ["kVK_Control", "kVK_ANSI_B", "kVK_Control", "kVK_ANSI_B", "kVK_Control", "kVK_ANSI_B", "kVK_Control", "kVK_ANSI_B", "kVK_Control", "kVK_ANSI_B"],
"{↓ 5}"         => ["kVK_Control", "kVK_ANSI_F", "kVK_Control", "kVK_ANSI_F", "kVK_Control", "kVK_ANSI_F", "kVK_Control", "kVK_ANSI_F", "kVK_Control", "kVK_ANSI_F"],
"+{→ 5}"        => ["kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P"],
"+{← 5}"        => ["kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N"],
"{→ 5}"         => ["kVK_Control", "kVK_ANSI_P", "kVK_Control", "kVK_ANSI_P", "kVK_Control", "kVK_ANSI_P", "kVK_Control", "kVK_ANSI_P", "kVK_Control", "kVK_ANSI_P"],
"{← 5}"         => ["kVK_Control", "kVK_ANSI_N", "kVK_Control", "kVK_ANSI_N", "kVK_Control", "kVK_ANSI_N", "kVK_Control", "kVK_ANSI_N", "kVK_Control", "kVK_ANSI_N"],
"^{PgUp}"       => ["kVK_Control", "kVK_PageUp"],
"^{PgDn}"       => ["kVK_Control", "kVK_PageDown"],
"^{PgUp 5}"     => ["kVK_Control", "kVK_PageUp", "kVK_Control", "kVK_PageUp", "kVK_Control", "kVK_PageUp", "kVK_Control", "kVK_PageUp", "kVK_Control", "kVK_PageUp"],
"^{PgDn 5}"     => ["kVK_Control", "kVK_PageDown", "kVK_Control", "kVK_PageDown", "kVK_Control", "kVK_PageDown", "kVK_Control", "kVK_PageDown", "kVK_Control", "kVK_PageDown"],
"{Enter}{End}"  => ["kVK_Return", "kVK_Control", "kVK_ANSI_E"],
"{Home}{改行}{Space 3}{End}" => ["kVK_Control", "kVK_ANSI_A", "kVK_Return", "kVK_Space", "kVK_Space", "kVK_Space", "kVK_Control", "kVK_ANSI_E"], # 台マクロ
"{Home}{改行}{Space 1}{End}" => ["kVK_Control", "kVK_ANSI_A", "kVK_Return", "kVK_Space", "kVK_Control", "kVK_ANSI_E"], # ト マクロ

"『』{改行}{↑}" => ["『』", "kVK_Control", "kVK_ANSI_B"],
"(){改行}{↑}" => ["()", "kVK_Control", "kVK_ANSI_B"],
"「」{改行}{↑}" => ["「」", "kVK_Control", "kVK_ANSI_B"],
"{改行}{End}{改行}「」{改行}{↑}" => ["kVK_Return", "kVK_Control", "kVK_ANSI_E", "kVK_Return", "「」", "kVK_Control", "kVK_ANSI_B"],
"【】{改行}{↑}" => ["【】", "kVK_Control", "kVK_ANSI_B"],
"{改行}{↓}" => ["kVK_Return", "kVK_Control", "kVK_ANSI_F"],
"{改行}{End}{改行}{Space}" => ["kVK_Return", "kVK_Control", "kVK_ANSI_E", "kVK_Return", "kVK_Space"],
"+{↑ 7}" => ["kVK_Shift", "kVK_Control", "kVK_ANSI_B", "kVK_Shift", "kVK_Control", "kVK_ANSI_B", "kVK_Shift", "kVK_Control", "kVK_ANSI_B", "kVK_Shift", "kVK_Control", "kVK_ANSI_B", "kVK_Shift", "kVK_Control", "kVK_ANSI_B"],
"+{↓ 7}" => ["kVK_Shift", "kVK_Control", "kVK_ANSI_F", "kVK_Shift", "kVK_Control", "kVK_ANSI_F", "kVK_Shift", "kVK_Control", "kVK_ANSI_F", "kVK_Shift", "kVK_Control", "kVK_ANSI_F", "kVK_Shift", "kVK_Control", "kVK_ANSI_F"],
"^x{BS}{Del}^v" => ["kVK_Command", "kVK_ANSI_X", "kVK_Delete", "kVK_ForwardDelete", "kVK_Command", "kVK_ANSI_V"],
"^x『^v』{改行}{Space}+{↑}^x" => ["kVK_Command", "kVK_ANSI_X", "『", "kVK_Command", "kVK_ANSI_V", "』", "kVK_Space", "kVK_Shift", "kVK_Control", "kVK_ANSI_B", "kVK_Command", "kVK_ANSI_X"],
"《》{改行}{↑}" => ["《》", "kVK_Control", "kVK_ANSI_B"],
"^x(^v){改行}{Space}+{↑}^x" => ["kVK_Command", "kVK_ANSI_X", "(", "kVK_Command", "kVK_ANSI_V", ")", "kVK_Space", "kVK_Shift", "kVK_Control", "kVK_ANSI_B", "kVK_Command", "kVK_ANSI_X"],
"^x「^v」{改行}{Space}+{↑}^x" => ["kVK_Command", "kVK_ANSI_X", "「", "kVK_Command", "kVK_ANSI_V", "」", "kVK_Space", "kVK_Shift", "kVK_Control", "kVK_ANSI_B", "kVK_Command", "kVK_ANSI_X"],
"^x｜{改行}^v《》{改行}{↑}{Space}+{↑}^x" => ["kVK_Command", "kVK_ANSI_X", "｜", "kVK_Command", "kVK_ANSI_V", "《》", "kVK_Control", "kVK_ANSI_B", "kVK_Space", "kVK_Shift", "kVK_Control", "kVK_ANSI_B", "kVK_Command", "kVK_ANSI_X"],
"^x【^v】{改行}{Space}+{↑}^x" => ["kVK_Command", "kVK_ANSI_X", "【", "kVK_Command", "kVK_ANSI_V", "】", "kVK_Space", "kVK_Shift", "kVK_Control", "kVK_ANSI_B", "kVK_Command", "kVK_ANSI_X"],
"{Home}{BS}{Del 3}{End}" => ["kVK_Control", "kVK_ANSI_A", "kVK_Delete", "kVK_ForwardDelete", "kVK_ForwardDelete", "kVK_ForwardDelete", "kVK_Control", "kVK_ANSI_E"],
"{Home}{BS}{Del 1}{End}" => ["kVK_Control", "kVK_ANSI_A", "kVK_Delete", "kVK_ForwardDelete", "kVK_Control", "kVK_ANSI_E"],
"+{→ 20}" => ["kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P", "kVK_Shift", "kVK_Control", "kVK_ANSI_P"],
"+{← 20}" => ["kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N", "kVK_Shift", "kVK_Control", "kVK_ANSI_N"],

"｜{改行}"      => ["｜"],
"・"           => ["kVK_ANSI_Slash"],
"……{改行}"     => ["……"],
"／{改行}"      => ["／"],
"《{改行}"      => ["《"],
"》{改行}"      => ["》"],
"「{改行}"      => ["「"],
"」{改行}"      => ["」"],
"({改行}"       => ["（"],
"){改行}"       => ["）"],
"││{改行}"      => ["││"],
"〇{改行}"      => ["〇"],
"【{改行}"      => ["【"],
"】{改行}"      => ["】"],
"〈{改行}"      => ["〈"],
"〉{改行}"      => ["〉"],
"『{改行}"      => ["『"],
"』{改行}"      => ["』"],

"｜{改行}{End}《》{改行}{↑}"=> ["｜", "kVK_Control", "kVK_ANSI_E", "《》", "kVK_Control", "kVK_ANSI_B"], # ルビ
"」{改行 2}「{改行}"=> ["」", "kVK_Return", "「"],
"」{改行 2}{Space}"=> ["」", "kVK_Return", "kVK_Space"],
"　　　×　　　×　　　×{改行 2}"=> ["　　　×　　　×　　　×", "kVK_Return"],

"{Space 3}"     => ["kVK_Space", "kVK_Space", "kVK_Space"],
"^i"            => ["kVK_Control", "kVK_ANSI_K"], # カタカナ
"^u"            => ["kVK_Control", "kVK_ANSI_J"], # ひらがな
"^s"            => ["kVK_Command", "kVK_ANSI_S"],
"^x"            => ["kVK_Command", "kVK_ANSI_X"],
"^v"            => ["kVK_Command", "kVK_ANSI_V"],
"^y"            => ["kVK_Command", "kVK_Shift", "kVK_ANSI_Z"],
"^z"            => ["kVK_Command", "kVK_ANSI_Z"],
"^c"            => ["kVK_Command", "kVK_ANSI_C"],

"{Home}{Del 3}{BS}{←}"    => ["kVK_Control", "kVK_ANSI_A", "kVK_ForwardDelete", "kVK_ForwardDelete", "kVK_ForwardDelete", "kVK_Delete", "kVK_Control", "kVK_ANSI_N"],
"^x｜{改行}^v《》{改行}{↑}" => ["kVK_Command", "kVK_ANSI_X", "｜", "kVK_Command", "kVK_ANSI_V", "《》", "kVK_Control", "kVK_ANSI_B"],
"{Home}{改行}{Space 3}{←}" => ["kVK_Control", "kVK_ANSI_A", "kVK_Return", "kVK_Space", "kVK_Space", "kVK_Space", "kVK_Control", "kVK_ANSI_N"],
"{Home}{Del 1}{BS}{←}" => ["kVK_Control", "kVK_ANSI_A", "kVK_ForwardDelete", "kVK_Delete", "kVK_Control", "kVK_ANSI_N"],
"{Home}{改行}{Space 1}{←}" => ["kVK_Control", "kVK_ANSI_A", "kVK_Return", "kVK_Space", "kVK_Control", "kVK_ANSI_N"],
"{改行}{End}{改行}}" => ["kVK_Return", "kVK_Control", "kVK_ANSI_E", "kVK_Return"],
"{End}{改行}" => ["kVK_Control", "kVK_ANSI_E", "kVK_Return"],
"+{→}" => ["kVK_Shift", "kVK_Control", "kVK_ANSI_P"],
"+{←}" => ["kVK_Shift", "kVK_Control", "kVK_ANSI_N"],

}

qwerty    = %w(Q W E R T  Y U I O P  A S D F G  H J K L Semicolon  Z X C V B  N M Comma Period Slash)

mode1l = mode1l.split("|").map{|x| x.strip}
mode1r = mode1r.split("|").map{|x| x.strip}
mode2l = mode2l.split("|").map{|x| x.strip}
mode2r = mode2r.split("|").map{|x| x.strip}

[mode1l, mode1r, mode2l, mode2r].each do |x|
  x.delete_at(35)
  x.delete_at(34)
  x.delete_at(23)
  x.delete_at(22)
  x.delete_at(11)
  x.delete_at(10)
end

$hwin = []
$hmac = []
$uwin = []
$umac = []
$htate = []

# def teigi(a, b, c, prefix="", suffix="")
# puts teigi(eiji[j], r_kana[i], k, "kVK_Space")

def teigi2(keys, outputs, comment, prefix=[], suffix=[])
  as = [keys].flatten.map{|k| "[NSNumber numberWithInt:kVK_ANSI_#{k}]"}
  prefix.each do |pf|
    as.unshift "[NSNumber numberWithInt:#{pf}]"
  end
  suffix.each do |sf|
    as.push "[NSNumber numberWithInt:#{sf}]"
  end
  as = as.join(", ")

  _b = []
  bs = outputs.map{|k|
    if k =~ /kVK_/
      "[NSNumber numberWithInt:#{k.strip}]"
    else
      "@\"#{k}\""
    end
  }.join(", ")

  sprintf("[NSArray arrayWithObjects: #{bs}, nil], [NSSet setWithObjects: #{as}, nil], // #{comment}")
end


puts "// 編集モード1"

qwerty.each_with_index do |k, i|
  unless $henshu.key? mode1l[i]
    puts "missing #{mode1l[i]}" if mode1l[i].size > 0
    next
  end
  m =  mode1l[i]
  l = $henshu[m]
  pk = ["kVK_ANSI_J", "kVK_ANSI_K"]
  puts teigi2(k, l, m, [], pk)
end

qwerty.each_with_index do |k, i|
  unless $henshu.key? mode1r[i]
    puts "missing #{mode1r[i]}" if mode1r[i].size > 0
    next
  end
  m =  mode1r[i]
  l = $henshu[m]
  pk = ["kVK_ANSI_D", "kVK_ANSI_F"]
  puts teigi2(k, l, m, [], pk)
end

puts "// 編集モード2"

qwerty.each_with_index do |k, i|
  unless $henshu.key? mode2l[i]
    puts "missing #{mode2l[i]}" if mode2l[i].size > 0
    next
  end
  m =  mode2l[i]
  l = $henshu[m]
  pk = ["kVK_ANSI_M", "kVK_ANSI_Comma"]
  puts teigi2(k, l, m, [], pk)
end

qwerty.each_with_index do |k, i|
  unless $henshu.key? mode2r[i]
    puts "missing #{mode2r[i]}" if mode2r[i].size > 0
    next
  end
  m =  mode2r[i]
  l = $henshu[m]
  pk = ["kVK_ANSI_C", "kVK_ANSI_V"]
  puts teigi2(k, l, m, [], pk)
end


puts "// 固有名詞"

def teigi3(key, prefix=[], suffix=[])
  as = ["[NSNumber numberWithInt:kVK_ANSI_#{key}]"]
  prefix.each do |pf|
    as.unshift "[NSNumber numberWithInt:#{pf}]"
  end
  suffix.each do |sf|
    as.push "[NSNumber numberWithInt:#{sf}]"
  end
  as = as.join(", ")

  bs = "@\"#{key.downcase}\""

  sprintf("[NSArray arrayWithObjects: [[ProperAction alloc] initWith:#{bs}], nil], [NSSet setWithObjects: #{as}, nil], // 固有名詞 #{key}")
end

eiji_r.each_with_index do |k, i|
  pk = ["kVK_ANSI_E", "kVK_ANSI_R"]
  puts teigi3(k, [], pk)
end

eiji_l.each_with_index do |k, i|
  pk = ["kVK_ANSI_U", "kVK_ANSI_I"]
  puts teigi3(k, [], pk)
end

