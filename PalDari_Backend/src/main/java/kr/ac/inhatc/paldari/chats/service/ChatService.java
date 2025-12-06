package kr.ac.inhatc.paldari.chats.service;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.chats.dto.ChatRoomResponse;
import kr.ac.inhatc.paldari.chats.entity.ChatMessage;
import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import kr.ac.inhatc.paldari.chats.entity.ChatRoomMember;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomMemberRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatMessageRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatService {

    private final ChatRoomRepository chatRoomRepository;
    private final ChatRoomMemberRepository chatRoomMemberRepository;
    private final UserRepository userRepository;
    // ⭐ 추가: 메시지 관련 쿼리용
    private final ChatMessageRepository chatMessageRepository;

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
            // ⭐ 현재 사용자(meId) 기준 buddyUserId 세팅
            return ChatRoomResponse.from(room, meId);
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
        return ChatRoomResponse.from(room, meId);
    }
    // ChatService.java

    @Transactional
    public void markRoomAsRead(Long meId, Long roomId) {
        // 1) 내 멤버 레코드 찾기
        ChatRoomMember myMember = chatRoomMemberRepository
                .findByRoomIdAndUserId(roomId, meId)
                .orElseThrow(() -> new IllegalArgumentException("이 방의 멤버가 아닙니다."));

        // 2) 이 방의 마지막 메시지 ID 조회
        Long lastMessageId = chatMessageRepository.findLastMessageIdByRoomId(roomId);
        if (lastMessageId == null) {
            return; // 메시지가 하나도 없으면 그냥 종료
        }

        // 3) 마지막으로 읽은 메시지 ID 갱신
        myMember.setLastReadMessageId(lastMessageId);
        // 👉 @Transactional + JPA dirty checking 으로 자동 저장됨
    }


    /**
     * 내가 속한 모든 채팅방 목록
     */
    @Transactional(readOnly = true)
    public List<ChatRoomResponse> getMyRooms(Long meId) {

        // ⭐ 추가: "나" 유저 조회해서 username 가져오기
        User me = userRepository.findById(meId)
                .orElseThrow(() -> new IllegalArgumentException("나를 찾을 수 없습니다. id=" + meId));

        var rooms = chatRoomMemberRepository.findRoomsByUserId(meId);

        return rooms.stream()
                .map(room -> {

                    User partner = chatRoomMemberRepository.findPartnerUser(room.getId(), meId);

                    String name;
                    String subText;
                    Long buddyId = null;

                    if (partner != null) {
                        name = partner.getUsername();
                        subText = buildSubTextForRoom(partner);
                        buddyId = partner.getId();
                    } else {
                        name = "(상대가 나감)";
                        subText = "";          // 또는 "대화를 종료한 상대입니다"
                        buddyId = 0L;          // ⭐ 프론트에서 0이면 상대 없음 처리
                    }

                    // ⭐ 나 자신의 멤버 정보
                    ChatRoomMember myMember =
                            chatRoomMemberRepository.findByRoomIdAndUserId(room.getId(), meId)
                                    .orElseThrow(() -> new IllegalStateException("멤버가 아님"));

                    Long lastReadId = (myMember.getLastReadMessageId() == null)
                            ? 0L
                            : myMember.getLastReadMessageId();

                    Long lastMessageId =
                            chatMessageRepository.findLastMessageIdByRoomId(room.getId());


                    int unread = 0;
                    if (lastMessageId != null) {
                        unread = (int) chatMessageRepository.countUnreadForUser(
                                room.getId(),
                                lastReadId,
                                me.getUsername(),               // 내가 보낸 건 제외하기 위해
                                ChatMessage.MessageType.TALK    // ⭐ enum 상수 전달
                        );
                    }

                    return ChatRoomResponse.builder()
                            .roomId(room.getId())
                            .name(name)
                            .buddyUserId(buddyId)
                            .subText(subText)
                            .unreadCount(unread)
                            .build();
                })
                .toList();
    }



    private String buildSubTextForRoom(User target) {
        // 다중 국적을 ", "로 join
        String countryText = (target.getCountries() == null || target.getCountries().isEmpty())
                ? null
                : String.join(", ", target.getCountries());

        String living = target.getLivingIn();

        if (countryText == null && living == null) return "";
        if (countryText != null && living != null) return countryText + " / " + living;
        return countryText != null ? countryText : living;
    }

    // 채팅방 나가기 로직
    @Transactional
    public void leaveRoom(Long roomId, Long userId) {

        // 1) 멤버인지 확인
        if (!chatRoomMemberRepository.existsByRoom_IdAndUser_Id(roomId, userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "해당 채팅방 멤버가 아닙니다.");
        }

        // 2) 멤버 row 삭제 = 내 목록에서 완전 삭제
        chatRoomMemberRepository.deleteByRoom_IdAndUser_Id(roomId, userId);

        // 3) 방에 남은 멤버가 0명이면 방 삭제
        long remain = chatRoomMemberRepository.countByRoom_Id(roomId);
        if (remain == 0) {
            chatRoomRepository.deleteById(roomId);
        }
    }

}
