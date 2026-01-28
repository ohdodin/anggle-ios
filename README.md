# 어디서나 간편한 재활 기록 앱, Anggle
<img width="3342" height="2101" alt="Project Image" src="https://github.com/user-attachments/assets/0ecc0d49-e8d5-4fb9-937b-ed9113f01766" />
<p/>
<p align="center">
  <a href="https://apps.apple.com/app/id6755084318" target="_blank" rel="noopener noreferrer">
    <img
      src="https://github.com/user-attachments/assets/42a08d54-97ec-4425-b984-bdc3dd91c6e6"
      alt="Download on the App Store"
      width="180"
    />
  </a>
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Swift-6.0+-orange" />
    <img src="https://img.shields.io/badge/Xcode-26.0+-blue" />
    <img src="https://img.shields.io/badge/iOS-17.0+-blue" />
</p>

## ✨ 소개

**Anggle** 은 iPhone의 모션 센서를 활용해 </br>
관절 가동 범위(ROM)와 통증 정도를 **빠르고 직관적으로 기록**할 수 있는 재활 기록 앱입니다. </br>
재활과정을 **숫자와 그래프로**로 한눈에 확인해보세요.
</br></br>

## 👭 팀원

<table>
  <tbody>
    <tr>
      <td align="center"><a href="https://github.com/romiwaves">PM | 전유진(Gabi)</a></td>
      <td align="center"><a href="https://github.com/ohdodin">DEV | 오서진(Dodin)</a></td>
     <tr/>
      <td align="center"><a href="https://github.com/romiwaves"><img width="160" height="160" alt="Yujin Jeon, Gabi" src="https://github.com/user-attachments/assets/fb8f58af-2ccb-4964-b5bf-aa802fdf540f" /></a></td>
      <td align="center"><a href="https://github.com/ohdodin"><img width="160" height="160" alt="Seojin Oh, Dodin" src="https://github.com/user-attachments/assets/3fd15dcb-05df-42d3-af83-91d36800e753" /></a></td>
     </tr>
  </tbody>
</table>

> 본 프로젝트는 **Apple Developer Academy @ POSTECH**에서 2025년 9월~2025년 11월까지 6인 팀 프로젝트로 시작되었습니다.  
> 2025년 12월부터 2인 프로젝트로 전환하여 지속적으로 개발하고 있습니다.
> 
> - **아카데미 프로젝트 기간**: 2025.09 ~ 2025.11
> - **원본 레포지토리**: [DeveloperAcademy-POSTECH/2025-C6-M14-Gacha](https://github.com/DeveloperAcademy-POSTECH/2025-C6-M14-Gacha)
> - **참여 팀원**: 전유진(PM), 오서진(Dev), 차원준(Dev), 김순주(UX Writer), 임준혁(Design), 황지민(Design)  
</br></br>

## 🎯 대상 사용자

- 무릎 수술(ACL 등) 후 회복 중인 사용자
- 재활 치료를 진행 중인 사용자
- 관절 가동 범위(ROM)를 **수치로 관리**하고 싶은 사용자
- 재활 경과를 **객관적인 데이터**로 확인하고 싶은 사용자
</br></br>

---

## 🧩 주요 기능

<table>
  <tr>
    <td align="center"><h3>📐 측정</h3></td>
    <td align="center"><h3>📊 기록</h3></td>
    <td align="center"><h3>🔍 분석</h3></td>
  </tr>
  <tr>
    <td width="280" align="center">
      <img
        src="https://github.com/user-attachments/assets/ff75f774-1042-4e43-b1a4-1cbf09af6ab5"
        width="256"
        alt="Feature1"
      />
    </td>
    <td width="280" align="center">
      <img
        src="https://github.com/user-attachments/assets/75931d96-18ef-43d9-8ac7-a634f479c947"
        width="256"
        alt="Feature2"
      />
    </td>
    <td width="280" align="center">
      <img
        src="https://github.com/user-attachments/assets/a7d28b95-9578-4ed7-93c9-18d187356343"
        width="256"
        alt="Feature3"
      />
    </td>
  </tr>
  <tr>
    <td>
      <ul>
        <li>무릎 관절 가동 범위(ROM)</li>
        <li>굴곡(Flexion) / 신전(Extension)</li>
        <li>통증 수준 기록 (VAS 0–10)</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>주간 ROM 변화 그래프</li>
        <li>측정 기록 히스토리</li>
        <li>통증 변화 추적</li>
      </ul>
    </td>
    <td>
      <ul>
        <li>이전 기록 대비 변화 비교</li>
        <li>상태 기반 피드백 제공</li>
        <li>악화 시 주의 안내</li>
      </ul>
    </td>
  </tr>
</table>
</br></br>

## ▶️ 사용 방법

1. 앉은 상태에서 측정할 다리 준비
2. iPhone을 허벅지 또는 정강이에 밀착
3. 측정 버튼을 누르고 자세 유지
4. 무릎을 굽혀 다시 측정
5. 통증 수준 입력 후 결과 확인
</br></br>

## 🛠 기술 스택

- **Language**: Swift  
- **UI**: SwiftUI  
- **Architecture**: MVVM  
- **Data**: SwiftData  
- **Sensor**: CoreMotion  
- **Chart**: Swift Charts
- **Minimum iOS**: 17.0+
</br></br>

## 🗂 프로젝트 구조

```text
gacha/
├── Models/
├── ViewModels/
├── Views/
│   ├── Measure/
│   ├── Progress/
│   └── Component/
└── DesignSystem/
```
</br></br>

## 📄 License

Copyright © 2025 Anggle Team.  
All rights reserved.
