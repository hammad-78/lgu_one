import 'model.dart';

class SocietyData {
  static List<Society> societies = [
    Society(
      id: "1",
      name: "SoftTech Society",
      description: "Tech events, hackathons & coding competitions.",
      imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRUDOG4dRGFtA19Oa00mvDtHM8oS7bqUHZNjw&s",
      memberCount: 500,
      presidentPhone: "3286433907",
    ),
    Society(
      id: "2",
      name: "Business Society",
      description: "Entrepreneurship & startup networking.",
      imageUrl: "https://via.placeholder.com/150?text=Business",
      memberCount: 420,
      presidentPhone: "3012345678",
    ),
    Society(
      id: "3",
      name: "Media Society",
      description: "Photography & videography community.",
      imageUrl: "https://via.placeholder.com/150?text=Media",
      memberCount: 300,
      presidentPhone: "3023456789",
    ),
    Society(
      id: "4",
      name: "Sports Society",
      description: "Cricket, football & fitness activities.",
      imageUrl: "https://via.placeholder.com/150?text=Sports",
      memberCount: 600,
      presidentPhone: "3034567890",
    ),
  ];
}