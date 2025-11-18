package kr.ac.inhatc.paldari.chats.service;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.chats.dto.ChatRoomResponse;
import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import kr.ac.inhatc.paldari.chats.entity.ChatRoomMember;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomMemberRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatService {

    private final ChatRoomRepository chatRoomRepository;
    private final ChatRoomMemberRepository chatRoomMemberRepository;
    private final UserRepository userRepository;

    /**
     * 매칭에서 "채팅 시작" 눌렀을 때:
     * - meId 와 targetUserId 사이의 1:1 방이 이미 있으면 그 방 리턴
     * - 없으면 새로 ChatRoom + ChatRoomMember(나, 상대) 2개 만들고 리턴
     */
    @Transactional
    public ChatRoomResponse createOrGetPrivateRoom(Long meId, Long targetUserId) {
        if (meId == null || targetUserId == null) {
            throw new IllegalArgumentException("meId / targetUserId 는 null 일 수 없습니다.");
        }
        if (meId.equals(targetUserId)) {
            throw new IllegalArgumentException("자기 자신과는 매칭할 수 없습니다.");
        }

        log.info("[ChatService] createOrGetPrivateRoom me={} target={}", meId, targetUserId);

        // 1) 둘 사이에 이미 존재하는 1:1 방이 있는지 확인
        var existing = chatRoomMemberRepository.findDirectRoomBetweenUsers(meId, targetUserId);
        if (existing.isPresent()) {
            ChatRoom room = existing.get();
            log.info("[ChatService] existing private room reused. roomId={}", room.getId());
            return ChatRoomResponse.from(room);
        }

        // 2) 유저 조회
        User me = userRepository.findById(meId)
                .orElseThrow(() -> new IllegalArgumentException("나를 찾을 수 없습니다. id=" + meId));
        User target = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("상대를 찾을 수 없습니다. id=" + targetUserId));

        // 3) 새 채팅방 생성 (표시용 name/subText 는 마음대로 꾸며도 됨)
        ChatRoom room = ChatRoom.builder()
                .name(target.getUsername())       // 나 기준으로 상대 이름
                .subText(buildSubTextForRoom(target)) // 예: 국가 / 도시 등
                .build();

        chatRoomRepository.save(room);
        log.info("[ChatService] new private room created. roomId={} for users {} & {}",
                room.getId(), meId, targetUserId);

        // 4) 방 멤버 2명 저장 (나 + 상대)
        ChatRoomMember myMember = ChatRoomMember.builder()
                .room(room)
                .user(me)
                .build();

        ChatRoomMember targetMember = ChatRoomMember.builder()
                .room(room)
                .user(target)
                .build();

        chatRoomMemberRepository.save(myMember);
        chatRoomMemberRepository.save(targetMember);

        log.info("[ChatService] chatRoomMember saved. roomId={} myMemberId={} targetMemberId={}",
                room.getId(), myMember.getId(), targetMember.getId());

        // 5) 프론트로 넘길 DTO
        return ChatRoomResponse.from(room);
    }

    /**
     * 내가 속한 모든 채팅방 목록
     */
    @Transactional(readOnly = true)
    public List<ChatRoomResponse> getMyRooms(Long meId) {
        var rooms = chatRoomMemberRepository.findRoomsByUserId(meId);

        return rooms.stream()
                .map(room -> {
                    // 🔹 이 방에서 "나(meId)가 아닌" 상대 유저 찾기
                    User partner = chatRoomMemberRepository.findPartnerUser(room.getId(), meId);

                    String name;
                    String subText;

                    if (partner != null) {
                        // 항상 상대 기준으로 이름/서브텍스트 구성
                        name = partner.getUsername();          // 필요하면 nickname 으로 변경 가능
                        subText = buildSubTextForRoom(partner);
                    } else {
                        // 혹시라도 null이면 기존 값 fallback
                        name = room.getName();
                        subText = room.getSubText();
                    }

                    return ChatRoomResponse.builder()
                            .roomId(room.getId())
                            .name(name)
                            .subText(subText)
                            .build();
                })
                .toList();
    }


    private String buildSubTextForRoom(User target) {
        String country = target.getCountry();
        String living = target.getLivingIn();
        if (country == null && living == null) return "";
        if (country != null && living != null) return country + " / " + living;
        return country != null ? country : living;
    }
}
