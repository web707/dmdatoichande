"""Generate professional English narration audio and store bilingual transcripts."""

import asyncio
from hashlib import sha256
import json
from pathlib import Path
import edge_tts

ROOT = Path(__file__).resolve().parents[1] / '.local/vr360/hoan-kiem'
PUBLIC = ROOT / 'public'
ASSETS = PUBLIC / 'assets'
TOUR_JSON = PUBLIC / 'tour.json'

VOICE_EN = 'en-US-ChristopherNeural'

TRANSCRIPTS = {
    "9861": {
        "titleVi": "Hồ Gươm trên cao",
        "titleEn": "Panoramic Aerial View",
        "textVi": "Chào mừng quý khách đến với Hồ Hoàn Kiếm - trái tim xanh ngàn năm tuổi của Thủ đô Hà Nội. Chiêm ngưỡng từ trên cao vẻ đẹp thơ mộng, Tháp Rùa cổ kính và nhịp sống của vùng đất kinh kỳ nghìn năm văn hiến.",
        "textEn": "Welcome to Hoan Kiem Lake, the thousand-year-old emerald heart of Hanoi. From this panoramic vantage point, explore the serene waters, the ancient Turtle Tower, and the timeless harmony between storied heritage and contemporary Vietnamese life."
    },
    "9847": {
        "titleVi": "Hồ Gươm",
        "titleEn": "Hoan Kiem Lake",
        "textVi": "Hồ Hoàn Kiếm còn được gọi là Hồ Gươm - trái tim xanh ngàn năm tuổi của thủ đô. Nhìn ra giữa lòng hồ, nơi ngọn Tháp Rùa cổ kính đang đứng trầm mặc, chúng ta như đang ngược dòng thời gian về với thế kỷ XV. Nơi đây gắn liền với truyền thuyết vua Lê Lợi hoàn gươm thần Thuận Thiên cho Rùa Vàng. Từng mang những cái tên như Lục Thủy, Thủy Quân, hay Tả Vọng, mặt nước rộng 12 héc-ta này là nơi lưu giữ trọn vẹn hồn thiêng sông núi và nhịp sống của mảnh đất kinh kỳ.",
        "textEn": "Hoan Kiem Lake, also affectionately known as the Lake of the Restored Sword, is the vibrant green heart of Hanoi. Gazing out toward Turtle Tower standing serenely in the mist, we journey back to the fifteenth century, steeped in the legend of Emperor Le Loi returning the divine sword to the Golden Turtle God. Once known as Luc Thuy, Thuy Quan, or Ta Vong, this twelve-hectare historic lake preserves the sacred soul and daily rhythm of Vietnam's ancient capital."
    },
    "9848": {
        "titleVi": "Đền Ngọc Sơn",
        "titleEn": "Ngoc Son Temple",
        "textVi": "Nằm trên đảo Ngọc giữa Hồ Hoàn Kiếm, đền Ngọc Sơn là một trong những biểu tượng văn hóa – lịch sử tiêu biểu của Thủ đô. Qua thời gian, nơi đây lưu giữ nhiều lớp giá trị tín ngưỡng, lịch sử và văn hóa Thăng Long. Từ cổng đền, một trục kiến trúc nối tiếp mở ra: Tháp Bút, Đài Nghiên, cầu Thê Húc, Đắc Nguyệt Lâu và đình Trấn Ba, tạo nên một quần thể hài hòa. Di tích Hồ Hoàn Kiếm - đền Ngọc Sơn đã được xếp hạng Di tích quốc gia đặc biệt năm 2013.",
        "textEn": "Perched gracefully upon Jade Island in Hoan Kiem Lake, Ngoc Son Temple is one of Hanoi’s most revered cultural and spiritual sanctuaries. Over the centuries, it has embraced multiple layers of Taoist, Confucian, and Buddhist heritage. From the temple gate, an exquisite architectural ensemble unfolds: Pen Tower, Ink Slab, The Huc Bridge, Moon Contemplation Pavilion, and Tran Ba Pavilion. Ngoc Son Temple was designated a Special National Monument in 2013."
    },
    "9849": {
        "titleVi": "Đền Bà Kiệu",
        "titleEn": "Ba Kieu Temple",
        "textVi": "Nằm trên phố Đinh Tiên Hoàng, là một trong những ngôi đền cổ gắn với tín ngưỡng thờ Mẫu ở Hà Nội. Được xây dựng vào đầu thế kỷ XVII, dưới niên hiệu Vĩnh Tộ (1619 - 1628) thời vua Lê Thần Tông. Đền Thờ Thánh Mẫu Liễu Hạnh cùng hai vị tiên nữ Quỳnh Hoa và Quế Nương. Điểm độc đáo của đền là kiến trúc bị \"cắt đôi\" bởi con đường Đinh Tiên Hoàng, với Tam quan nằm sát bờ hồ. Năm 1994, đền được xếp hạng Di tích lịch sử – văn hóa cấp quốc gia. Kiến trúc đền mang đậm phong cách thời Nguyễn với các chi tiết chạm khắc tinh xảo, sơn son thếp vàng, tạo nên diện mạo nghệ thuật đặc trưng của không gian thờ tự thời Nguyễn.",
        "textEn": "Located along Dinh Tiên Hoang Street, Ba Kieu Temple is one of Hanoi's oldest shrines dedicated to the indigenous Mother Goddess faith. Built in the early seventeenth century during the reign of King Le Than Tong, it honors Holy Mother Lieu Hanh alongside fairy attendants Quynh Hoa and Que Nuong. Uniquely, the temple's ceremonial gate and main sanctuary were physically separated by modern road construction, with the gate standing proudly on the lakeside. Celebrated for its intricate Nguyen dynasty wood carvings and gilded lacquering, it was recognized as a National Cultural and Historical Monument in 1994."
    },
    "9850": {
        "titleVi": "Tượng đài cảm tử",
        "titleEn": "Martyrs Monument",
        "textVi": "Nằm trong khuôn viên di tích đền Bà Kiệu, hướng mặt ra phố Đinh Tiên Hoàng và Hồ Gươm lịch sử, tượng đài Cảm tử từ lâu đã trở thành một biểu tượng tinh thần vô giá của Thủ đô. Tượng đài Cảm tử được xây dựng năm 1984, nhân kỷ niệm 30 năm Ngày Giải phóng Thủ đô. Tên công trình được lấy từ câu nói trong thư của Chủ tịch Hồ Chí Minh. Lời thề \"Quyết tử để Tổ quốc quyết sinh\" bác Hồ gửi tặng các chiến sĩ Trung đoàn Thủ đô nhân dịp Tết Đinh Hợi (1947).",
        "textEn": "Set within the courtyard of Ba Kieu Temple facing Hoan Kiem Lake, the Martyrs Monument is a poignant tribute to Hanoi's heroic past. Unveiled in 1984 to mark the 30th anniversary of Capital Liberation Day, the monument immortalizes President Ho Chi Minh’s historic commendation to the Capital Regiment during the 1947 resistance: 'Determined to brave death so that the Fatherland may live'."
    },
    "9851": {
        "titleVi": "Báo Nhân Dân",
        "titleEn": "Nhan Dan Newspaper Headquarters",
        "textVi": "Tọa lạc tại số 71 phố Hàng Trống, Hà Nội, trụ sở Báo Nhân Dân là nơi gắn bó với nhiều dấu mốc trong lịch sử báo chí cách mạng Việt Nam. Sau ngày giải phóng Thủ đô năm 1954, Báo Nhân Dân chuyển trụ sở về đây. Bên trong khuôn viên tòa soạn có một cây đa cổ thụ lâu năm, góp phần tạo nên nét đặc trưng cho không gian nơi này.",
        "textEn": "Situated at 71 Hang Trong Street, the headquarters of Nhan Dan Newspaper has long been intertwined with milestones of Vietnamese revolutionary journalism. Establishing its headquarters here following the 1954 liberation of Hanoi, the compound features grand French-era colonial architecture centered around an iconic three-century-old banyan tree."
    },
    "9852": {
        "titleVi": "Cây đa Nhân Dân",
        "titleEn": "The Historic Banyan Tree",
        "textVi": "Trong khuôn viên có một cây đa cổ thụ đã hơn 300 năm tuổi. Trải qua nhiều năm, cây vẫn được gìn giữ, trở thành một phần quen thuộc của Báo Nhân Dân.",
        "textEn": "Standing quietly within the courtyard is a magnificent heritage banyan tree over 300 years old. Having witnessed centuries of city history, its spreading canopy remains a beloved green icon of Hanoi's historic Old Quarter."
    },
    "9853": {
        "titleVi": "Đình Nam Hương",
        "titleEn": "Nam Huong Communal House",
        "textVi": "Nằm tại số 75 phố Hàng Trống, đình Nam Hương nằm phía sau khu tưởng niệm Vua Lê Thái Tổ. Nơi đây là một trong những khu vực lưu giữ dấu ấn lịch sử và văn hóa của Hà Nội và được xếp hạng Di tích lịch sử - văn hóa, kiến trúc nghệ thuật cấp Quốc gia vào năm 1995. Đình Nam Hương được dựng từ thời Lê để thờ các vị Thượng đẳng thần là: Thần Long Đỗ (thần Bạch Mã), thần Cao Sơn đại vương, thần Linh Lang đại vương, công chúa Á Duy và thần Kha Duy. Đặc biệt, đình là một trong những di tích hiếm hoi gắn với cả bốn vị thần trong hệ thống Thăng Long tứ trấn: Bạch Mã trấn phía Đông, Cao Sơn trấn phía Nam và Linh Lang trấn phía Tây.",
        "textEn": "Located at 75 Hang Trong Street, Nam Huong Communal House is an esteemed sanctuary designated as a National Monument in 1995. Founded during the Le dynasty, it honors supreme guardian deities including Long Do (the White Horse God), Cao Son, and Linh Lang. Remarkably, it is one of the rare sites linked to three of the Four Sacred Guardian Spirits of ancient Thang Long."
    },
    "9855": {
        "titleVi": "Đền vua Lê Thái Tổ",
        "titleEn": "King Le Thai To Memorial",
        "textVi": "Tượng đài vua Lê Thái Tổ nằm trong một quần thể kiến trúc nhiều hạng mục tại số 16 phố Lê Thái Tổ. Quần thể kiến trúc tưởng niệm vua Lê do Kinh lược sứ Bắc Kỳ Hoàng Cao Khải dựng vào năm 1894, để tưởng nhớ công ơn vị vua đã đánh thắng giặc ngoại xâm, giành độc lập cho dân tộc. Quần thể gồm 3 hạng mục chính, bố cục đăng đối theo một trục thần đạo, từ ngoài vào trong là cổng, sân vườn, nhà phương đình và tượng đài.",
        "textEn": "The King Le Thai To Memorial Complex at 16 Le Thai To Street was erected in 1894 by Viceroy Hoang Cao Khai to honor the national hero who triumphed over foreign invaders to reclaim independence in 1428. Arranged symmetrically along a ceremonial axis, it includes an ornate gateway, courtyard, pavilion, and a bronze statue of Emperor Le Loi brandishing the divine sword."
    },
    "9856": {
        "titleVi": "Bưu điện Hà Nội",
        "titleEn": "Hanoi Central Post Office",
        "textVi": "Nằm bên Hồ Gươm thơ mộng, Bưu điện Hà Nội nổi bật với vẻ đẹp cổ kính, trang nghiêm, mang đậm dấu ấn kiến trúc Pháp. Công trình này không chỉ là nơi giao thương bưu chính quan trọng mà còn là biểu tượng văn hóa, lịch sử của Thủ đô Hà Nội.",
        "textEn": "Gracing the eastern bank of Hoan Kiem Lake, the Hanoi Post Office is distinguished by its stately neoclassical architecture and iconic public clock tower. It stands not only as an essential postal gateway but also as an enduring witness to the city's modern cultural history."
    },
    "9857": {
        "titleVi": "Bắc Bộ Phủ",
        "titleEn": "Government Guest House (Bac Bo Phu)",
        "textVi": "Bắc Bộ phủ, nay là Nhà khách Chính phủ tọa lạc 12 Ngô Quyền, là một di tích lịch sử - văn hóa quan trọng của Thủ đô Hà Nội. Đây là nơi ghi dấu cuộc Tổng khởi nghĩa giành chính quyền (19-8-1945) của nhân dân Thủ đô, cũng là nơi Chủ tịch Hồ Chí Minh từng sống, làm việc sau Cách mạng Tháng Tám cho đến ngày Toàn quốc kháng chiến. Ngày nay, Bắc Bộ phủ là một di tích - điểm đến quan trọng của thành phố Hà Nội.",
        "textEn": "The Government Guest House, originally known as the Tonkin Governor's Palace (Bac Bo Phu), is a premier French colonial landmark at 12 Ngo Quyen Street. It bore witness to the August 19, 1945 uprising to seize power and served as President Ho Chi Minh's residence and office in the formative early months of the Democratic Republic of Vietnam."
    },
    "9858": {
        "titleVi": "Vườn hoa Lý Thái Tổ",
        "titleEn": "Ly Thai To Park",
        "textVi": "Nằm bên hồ Hoàn Kiếm, giữa bốn tuyến phố Đinh Tiên Hoàng, Lê Lai, Lê Thạch và Ngô Quyền, vườn hoa Lý Thái Tổ là một trong những không gian công cộng quan trọng gắn liền với cảnh quan Hồ Gươm. Nổi bật tại đây là tượng đài vua Lý Thái Tổ, được khánh thành ngày 7/10/2004, do UBND thành phố Hà Nội thực hiện nhân dịp kỷ niệm 50 năm Ngày Giải phóng Thủ đô.",
        "textEn": "Bordering Hoan Kiem Lake between four bustling streets, Ly Thai To Park is one of Hanoi’s most lively gathering places. At its focal point stands the imposing bronze monument of Emperor Ly Thai To, inaugurated in 2004, honoring the royal founder who established Thang Long—modern-day Hanoi—as the imperial capital in the year 1010."
    },
    "9859": {
        "titleVi": "UBND TP Hà Nội",
        "titleEn": "Hanoi City Hall",
        "textVi": "Ủy ban nhân dân thành phố Hà Nội là cơ quan hành chính nhà nước nằm trong hệ thống hành chính Cộng hòa xã hội chủ nghĩa Việt Nam. Đây là cơ quan chấp hành của Hội đồng nhân dân thành phố Hà Nội, cơ quan hành chính nhà nước ở thành phố Hà Nội, chịu trách nhiệm trước Hội đồng nhân dân thành phố và cơ quan nhà nước ở Trung ương Nhà nước Việt Nam, chịu trách nhiệm chấp hành Hiến pháp Việt Nam, pháp luật, các văn bản của Chính phủ Việt Nam và các Nghị quyết của Hội đồng nhân dân thành phố.",
        "textEn": "Hanoi City Hall, the seat of the Hanoi People’s Committee, overlooks Hoan Kiem Lake with dignified modern architecture. As the municipal executive government of the capital, it oversees civic administration, public services, and the flourishing development of this ancient metropolis."
    },
    "9860": {
        "titleVi": "Cầu Thê Húc",
        "titleEn": "The Huc Bridge",
        "textVi": "Trước mắt chúng ta là cầu Thê Húc – cây cầu đỏ “cong cong như con tôm”. Hình ảnh cây cầu đã trở nên quen thuộc trong thơ ca, ca dao và ký ức của nhiều thế hệ. Từ trên cầu, có thể phóng tầm mắt ra mặt Hồ Gươm, thu trọn vẻ xanh biếc của mặt nước và Tháp Rùa cổ kính. Cây cầu không chỉ là lối dẫn vào đền, mà còn là một trong những hình ảnh biểu tượng của Hà Nội. Bước qua cầu, chúng ta sẽ đến không gian thờ tự của Đền Ngọc Sơn, nơi thờ Đức Thánh Trần Hưng Đạo và Văn Xương Đế Quân, đồng thời lưu giữ hai tiêu bản của “cụ Rùa”.",
        "textEn": "Before us stretches The Huc Bridge—the iconic, scarlet wooden bridge gently arching like a crescent across the tranquil water. Meaning 'Perch of Morning Sunlight', this legendary bridge connects the lakeshore to Ngoc Son Temple, offering panoramic vistas across the emerald lake toward the historic Turtle Tower. Stepping across, visitors enter the sacred halls honoring Saint Tran Hung Dao and the God of Literature, while gazing upon the famous preserved specimens of the historic giant turtles."
    }
}


async def generate_speech(text: str, filename: str) -> str:
    path = ASSETS / filename
    if not path.exists():
        tts = edge_tts.Communicate(text, VOICE_EN, rate="-2%")
        await tts.save(str(path))
    return f'data/assets/{filename}'


async def main():
    print("Loading tour.json...")
    with open(TOUR_JSON, 'r', encoding='utf-8') as f:
        tour = json.load(f)

    for scene in tour['scenes']:
        scene_id = scene['id']
        info = TRANSCRIPTS.get(scene_id)
        if not info:
            continue

        scene['titleVi'] = info['titleVi']
        scene['titleEn'] = info['titleEn']
        scene['textVi'] = info['textVi']
        scene['textEn'] = info['textEn']

        # Store Vietnamese audio
        scene['audioVi'] = scene.get('audio')

        # Generate English speech audio
        en_audio_name = f'audio-en-{scene_id}.mp3'
        print(f"Generating English speech for scene {scene_id} ({info['titleEn']})...")
        en_audio_path = await generate_speech(info['textEn'], en_audio_name)
        scene['audioEn'] = en_audio_path

    with open(TOUR_JSON, 'w', encoding='utf-8') as f:
        json.dump(tour, f, ensure_ascii=False, indent=2)

    print("Successfully updated tour.json with bilingual transcripts and English audio!")


if __name__ == '__main__':
    asyncio.run(main())
